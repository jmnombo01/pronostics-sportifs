<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Services\CinetPayService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class CinetPayWebhookController extends Controller
{
    protected CinetPayService $cinetPayService;

    public function __construct(CinetPayService $cinetPayService)
    {
        $this->cinetPayService = $cinetPayService;
    }

    /**
     * Traiter le Webhook CinetPay après chaque paiement (Mobile Money ou Carte Bancaire)
     */
    public function webhook(Request $request)
    {
        Log::info('Webhook CinetPay reçu : ', $request->all());

        $result = $this->cinetPayService->handleWebhook($request->all());

        if ($result['success']) {
            return response()->json([
                'code' => '00',
                'message' => 'Traitement réussi',
                'data' => $result,
            ], 200);
        }

        return response()->json([
            'code' => '01',
            'message' => $result['message'],
        ], 400);
    }

    /**
     * URL de retour du paiement
     */
    public function returnUrl(Request $request)
    {
        return response()->json([
            'success' => true,
            'message' => 'Merci pour votre paiement. Votre abonnement est en cours de validation automatique.',
            'query' => $request->all(),
        ]);
    }
}
