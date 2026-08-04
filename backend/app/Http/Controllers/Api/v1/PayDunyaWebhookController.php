<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Services\PayDunyaService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PayDunyaWebhookController extends Controller
{
    protected PayDunyaService $payDunyaService;

    public function __construct(PayDunyaService $payDunyaService)
    {
        $this->payDunyaService = $payDunyaService;
    }

    /**
     * Endpoint IPN (Instant Payment Notification) de PayDunya
     */
    public function ipn(Request $request)
    {
        Log::info('IPN PayDunya reçu : ', $request->all());

        $result = $this->payDunyaService->handleIpn($request->all());

        if ($result['success']) {
            return response()->json([
                'code' => '00',
                'message' => 'Traitement IPN PayDunya réussi',
                'data' => $result,
            ], 200);
        }

        return response()->json([
            'code' => '01',
            'message' => $result['message'],
        ], 400);
    }

    /**
     * URL de retour succès
     */
    public function returnUrl(Request $request)
    {
        return response()->json([
            'success' => true,
            'gateway' => 'PAYDUNYA',
            'message' => 'Merci pour votre paiement PayDunya. Votre abonnement VIP est en cours d\'activation automatique.',
            'query' => $request->all(),
        ]);
    }

    /**
     * URL d'annulation
     */
    public function cancelUrl(Request $request)
    {
        return response()->json([
            'success' => false,
            'gateway' => 'PAYDUNYA',
            'message' => 'Le paiement PayDunya a été annulé.',
        ], 200);
    }
}
