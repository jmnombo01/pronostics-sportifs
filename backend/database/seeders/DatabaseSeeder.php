<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\SubscriptionPlan;
use App\Models\UserSubscription;
use App\Models\Prediction;
use App\Models\PromoCode;
use App\Models\Faq;
use Carbon\Carbon;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $now = Carbon::now();

        // 1. Création des Forfaits d'abonnement (VIP & Montante)
        $vipPlan = SubscriptionPlan::create([
            'code' => 'VIP',
            'name' => 'Abonnement VIP Mensuel',
            'price' => 2000,
            'duration_days' => 30,
            'description' => 'Accès complet aux pronostics Côte 5, Côte 10 et au Pronostic de la Semaine (Côte min 50).',
            'features_json' => [
                'Côte 5 quotidienne garantie',
                'Côte 10 exclusive',
                'Pronostic Semaine (Côte ≥ 50)',
                'Analyse détaillée des matchs',
                'Support VIP prioritaire',
            ],
            'is_active' => true,
        ]);

        $montantePlan = SubscriptionPlan::create([
            'code' => 'MONTANTE',
            'name' => 'Abonnement Montante Hebdomadaire',
            'price' => 2000,
            'duration_days' => 7,
            'description' => 'Accès exclusif et dédié à la stratégie Montante sur 7 jours.',
            'features_json' => [
                'Pronostics Montante exclusifs',
                'Gestion de mise pas-à-pas',
                'Statistiques de progression',
                'Accès 7 jours renouvelable',
            ],
            'is_active' => true,
        ]);

        // 2. Création de l'Administrateur principal unique
        $admin = User::create([
            'last_name' => 'Admin',
            'first_name' => 'Frogazz',
            'phone' => '+22600000000',
            'email' => 'admin@frogazz.pro',
            'password' => Hash::make('Frogazz@Admin2026'),
            'is_admin' => true,
            'subscription_status' => 'FREE',
            'subscription_expires_at' => null,
            'referral_code' => 'ADMINVIP',
        ]);

        // 3. Mode 100% réel : Zéro pronostic ou utilisateur fictif inséré !
        // Les pronostics et combinés officiels seront saisis par l'administrateur depuis le tableau de bord web.

        // 8. Codes Promo : AUCUN code promo fictif. Les codes sont créés par l'administrateur.

        // 9. FAQ
        $faqs = [
            [
                'question' => 'Comment fonctionne le mode gratuit ?',
                'answer' => 'Dès votre inscription, vous accédez gratuitement au Combiné Gratuit de 3 matchs publié chaque jour. Les catégories Côte 5, Côte 10, Côte 50 et Montante nécessitent un abonnement payant.',
                'category' => 'ABONNEMENT',
                'display_order' => 1,
            ],
            [
                'question' => 'Quelles sont les différences entre l\'offre VIP et Montante ?',
                'answer' => 'L\'abonnement VIP (2000 FCFA/mois) vous ouvre l\'accès aux catégories Côte 5, Côte 10 et au Pronostic de la Semaine (Côte 50). L\'abonnement Montante (2000 FCFA/semaine) est dédié aux pronostics de gestion de mise progressive (Montante).',
                'category' => 'ABONNEMENT',
                'display_order' => 2,
            ],
            [
                'question' => 'Quels moyens de paiement sont acceptés via CinetPay ?',
                'answer' => 'Vous pouvez payer en toute sécurité via Mobile Money (Orange Money, MTN Mobile Money, Moov Money, Airtel Money) ou par Carte Bancaire (Visa / Mastercard).',
                'category' => 'PAIEMENT',
                'display_order' => 3,
            ],
            [
                'question' => 'Quand les pronostics sont-ils publiés chaque jour ?',
                'answer' => 'Nos experts publient les pronostics quotidiennement entre 08h00 et 11h00 GMT. Vous recevez une notification push automatique dès qu\'un nouveau pronostic est en ligne !',
                'category' => 'PRONOSTICS',
                'display_order' => 4,
            ],
        ];

        foreach ($faqs as $faq) {
            Faq::create($faq);
        }
    }
}
