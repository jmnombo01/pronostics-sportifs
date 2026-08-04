<?php

namespace App\Http\Controllers\Api\v1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AdminAccountingController extends Controller
{
    /**
     * Rapport comptable des paiements CinetPay par mois et par opérateur (Orange Money, MTN, Moov, Airtel, CB)
     */
    public function report(Request $request)
    {
        $year = $request->input('year', Carbon::now()->year);

        // Bilan par opérateur
        $byOperator = Payment::where('status', 'ACCEPTED')
            ->whereYear('paid_at', $year)
            ->select('operator_id', DB::raw('count(*) as total_transactions'), DB::raw('sum(amount) as total_amount'))
            ->groupBy('operator_id')
            ->get()
            ->map(function ($row) {
                return [
                    'operator' => $row->operator_id ?: 'MOBILE_MONEY',
                    'transactions_count' => (int) $row->total_transactions,
                    'amount_fcfa' => (int) $row->total_amount,
                ];
            });

        // Bilan mensuel
        $byMonth = Payment::where('status', 'ACCEPTED')
            ->whereYear('paid_at', $year)
            ->select(DB::raw('MONTH(paid_at) as month'), DB::raw('count(*) as count'), DB::raw('sum(amount) as amount'))
            ->groupBy('month')
            ->orderBy('month')
            ->get()
            ->map(function ($row) {
                return [
                    'month_number' => (int) $row->month,
                    'month_name' => Carbon::create()->month((int) $row->month)->translatedFormat('F'),
                    'transactions_count' => (int) $row->count,
                    'amount_fcfa' => (int) $row->amount,
                ];
            });

        $totalRevenue = Payment::where('status', 'ACCEPTED')->whereYear('paid_at', $year)->sum('amount');
        $totalTransactions = Payment::where('status', 'ACCEPTED')->whereYear('paid_at', $year)->count();

        return response()->json([
            'success' => true,
            'year' => (int) $year,
            'summary' => [
                'total_transactions' => (int) $totalTransactions,
                'total_revenue_fcfa' => (int) $totalRevenue,
            ],
            'breakdown_by_operator' => $byOperator,
            'breakdown_by_month' => $byMonth,
        ]);
    }

    /**
     * Exporter le journal des transactions au format CSV (compatible Excel)
     */
    public function exportCsv(Request $request)
    {
        $payments = Payment::with(['user', 'plan'])->orderBy('paid_at', 'desc')->get();

        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="bilan_cinetpay_' . Carbon::now()->format('Ymd') . '.csv"',
        ];

        $callback = function () use ($payments) {
            $file = fopen('php://output', 'w');
            // En-tête BOM pour Excel UTF-8
            fprintf($file, chr(0xEF) . chr(0xBB) . chr(0xBF));

            fputcsv($file, [
                'ID Transaction',
                'ID Utilisateur',
                'Nom Utilisateur',
                'Téléphone',
                'Email',
                'Forfait',
                'Montant (FCFA)',
                'Opérateur (CinetPay)',
                'Statut',
                'Date de Paiement'
            ], ';');

            foreach ($payments as $pay) {
                fputcsv($file, [
                    $pay->transaction_id,
                    $pay->user_id,
                    $pay->user ? "{$pay->user->first_name} {$pay->user->last_name}" : 'N/A',
                    $pay->user ? $pay->user->phone : 'N/A',
                    $pay->user ? $pay->user->email : 'N/A',
                    $pay->plan ? $pay->plan->name : 'N/A',
                    $pay->amount,
                    $pay->operator_id ?: $pay->payment_method,
                    $pay->status,
                    $pay->paid_at ? $pay->paid_at->format('Y-m-d H:i:s') : $pay->created_at->format('Y-m-d H:i:s'),
                ], ';');
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }
}
