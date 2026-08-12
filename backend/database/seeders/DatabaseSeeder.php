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
            'last_name' => 'Traoré',
            'first_name' => 'Sidi (Admin)',
            'phone' => '+22670000001',
            'email' => 'admin@frogazz.pro',
            'password' => Hash::make('Password123!'),
            'is_admin' => true,
            'subscription_status' => 'ACTIVE',
            'subscription_expires_at' => $now->copy()->addYears(10),
            'referral_code' => 'ADMINVIP',
        ]);

        // 3. Mode 100% réel : Zéro pronostic ou utilisateur fictif inséré !
        // Les pronostics et combinés officiels seront saisis par l'administrateur depuis le tableau de bord web.

        // 8. Codes Promo
        PromoCode::create([
            'code' => 'WELCOME10',
            'discount_percent' => 10,
            'max_uses' => 500,
            'used_count' => 12,
            'is_active' => true,
        ]);

        PromoCode::create([
            'code' => 'VIP20',
            'discount_percent' => 20,
            'max_uses' => 100,
            'used_count' => 5,
            'is_active' => true,
        ]);

        // 9. FAQ
        $faqs = [
            [
                'question' => 'Comment fonctionne l\'essai gratuit de 48 heures ?',
                'answer' => 'Dès votre inscription, votre compte bénéficie de 48 heures d\'accès gratuit à tous les pronostics de la catégorie Côte 5. Après 48 heures, il suffit de s\'abonner pour continuer à recevoir nos analyses.',
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
