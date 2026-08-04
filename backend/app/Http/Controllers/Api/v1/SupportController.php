<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Faq;
use Illuminate\Http\Request;

class SupportController extends Controller
{
    /**
     * Liste des questions fréquentes (FAQ)
     */
    public function faqs()
    {
        $faqs = Faq::where('is_active', true)->orderBy('display_order', 'asc')->get();

        return response()->json([
            'success' => true,
            'data' => $faqs,
        ]);
    }

    /**
     * Lien de contact WhatsApp direct
     */
    public function whatsapp()
    {
        $number = env('WHATSAPP_SUPPORT_NUMBER', '+22670000000');
        $message = urlencode("Bonjour l'équipe Pronostics Sportifs ! J'ai besoin d'une assistance concernant mon compte/abonnement.");
        $url = "https://wa.me/" . ltrim($number, '+') . "?text=" . $message;

        return response()->json([
            'success' => true,
            'whatsapp_number' => $number,
            'whatsapp_url' => $url,
        ]);
    }

    /**
     * Conditions Générales d'Utilisation (CGU)
     */
    public function terms()
    {
        return response()->json([
            'success' => true,
            'title' => 'Conditions Générales d\'Utilisation',
            'content' => "1. Objet : Les présentes conditions régissent l'utilisation de l'application Pronostics Sportifs.\n\n2. Essai Gratuit : Chaque nouvel utilisateur bénéficie de 48 heures d'essai gratuit limitées à la catégorie Côte 5.\n\n3. Abonnements : L'abonnement VIP (2000 FCFA/mois) donne accès aux pronostics Côte 5, 10 et 50. L'abonnement Montante (2000 FCFA/semaine) donne uniquement accès à la section Montante.\n\n4. Responsabilité : Les pronostics fournis constituent des analyses et conseils d'experts, mais ne garantissent en aucun cas un gain sûr. Jouez de manière responsable.",
            'updated_at' => '2026-08-01',
        ]);
    }

    /**
     * Politique de confidentialité
     */
    public function privacy()
    {
        return response()->json([
            'success' => true,
            'title' => 'Politique de Confidentialité',
            'content' => "1. Collecte des Données : Nous collectons uniquement votre nom, prénom, email, téléphone et les données strictement nécessaires au fonctionnement de votre compte.\n\n2. Sécurité : Toutes vos données sont chiffrées selon les normes industrielles en vigueur (SSL/TLS, Sanctum).\n\n3. Paiements : Vos transactions financières sont traitées de manière sécurisée par notre partenaire CinetPay.",
            'updated_at' => '2026-08-01',
        ]);
    }
}
