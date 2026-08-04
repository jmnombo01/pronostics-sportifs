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

        // 2. Création de l'Administrateur principal
        $admin = User::create([
            'last_name' => 'Traoré',
            'first_name' => 'Sidi (Admin)',
            'phone' => '+22670000001',
            'email' => 'admin@pronostics.pro',
            'password' => Hash::make('Password123!'),
            'is_admin' => true,
            'subscription_status' => 'ACTIVE',
            'subscription_expires_at' => $now->copy()->addYears(10),
            'referral_code' => 'ADMINVIP',
        ]);

        // 3. Utilisateur VIP actif
        $vipUser = User::create([
            'last_name' => 'Sawadogo',
            'first_name' => 'Amadou (VIP)',
            'phone' => '+22670000002',
            'email' => 'vip@pronostics.pro',
            'password' => Hash::make('Password123!'),
            'is_admin' => false,
            'subscription_status' => 'ACTIVE',
            'subscription_expires_at' => $now->copy()->addDays(25),
            'referral_code' => 'SAWAD2026',
        ]);
        UserSubscription::create([
            'user_id' => $vipUser->id,
            'subscription_plan_id' => $vipPlan->id,
            'status' => 'ACTIVE',
            'starts_at' => $now->copy()->subDays(5),
            'expires_at' => $now->copy()->addDays(25),
        ]);

        // 4. Utilisateur Montante actif
        $montanteUser = User::create([
            'last_name' => 'Ouédraogo',
            'first_name' => 'Issa (Montante)',
            'phone' => '+22670000003',
            'email' => 'montante@pronostics.pro',
            'password' => Hash::make('Password123!'),
            'is_admin' => false,
            'subscription_status' => 'ACTIVE',
            'subscription_expires_at' => $now->copy()->addDays(5),
            'referral_code' => 'ISSA2026',
        ]);
        UserSubscription::create([
            'user_id' => $montanteUser->id,
            'subscription_plan_id' => $montantePlan->id,
            'status' => 'ACTIVE',
            'starts_at' => $now->copy()->subDays(2),
            'expires_at' => $now->copy()->addDays(5),
        ]);

        // 5. Utilisateur en essai gratuit 48h (Côte 5 libre)
        User::create([
            'last_name' => 'Kaboré',
            'first_name' => 'Fatima (Essai 48h)',
            'phone' => '+22670000004',
            'email' => 'trial@pronostics.pro',
            'password' => Hash::make('Password123!'),
            'is_admin' => false,
            'subscription_status' => 'FREE_TRIAL',
            'free_trial_expires_at' => $now->copy()->addHours(36),
            'referral_code' => 'FATIMA48',
        ]);

        // 6. Utilisateur avec essai gratuit expiré (>48h et non-abonné -> accès bloqué)
        User::create([
            'last_name' => 'Sanou',
            'first_name' => 'Brahima (Expiré)',
            'phone' => '+22670000005',
            'email' => 'expired@pronostics.pro',
            'password' => Hash::make('Password123!'),
            'is_admin' => false,
            'subscription_status' => 'EXPIRED',
            'free_trial_expires_at' => $now->copy()->subDays(3),
            'referral_code' => 'SANOUEXP',
        ]);

        // 7. Création de Pronostics réalistes de chaque catégorie (Combinés Frogazz Côte 5, 10, 50)
        $predictions = [
            [
                'title' => '🐸 COMBINÉ FROGAZZ CÔTE 5 DU LUNDI (3 MATCHS)',
                'competition' => 'Europe - Combiné VIP Frogazz',
                'country' => 'Europe',
                'championship' => 'Combiné Europe',
                'match_date' => $now->copy()->format('Y-m-d'),
                'match_time' => '19:30',
                'home_team' => 'Real Madrid / PSG / Bayern',
                'away_team' => 'Séville / Lyon / Leipzig',
                'type' => 'COTE_5',
                'odds' => 5.18,
                'confidence' => 5,
                'selections_json' => [
                    [
                        'match' => 'Real Madrid vs FC Séville',
                        'championship' => 'La Liga - Espagne',
                        'match_time' => '19:30',
                        'tip' => 'Victoire Real Madrid (1)',
                        'odds' => 1.65,
                        'status' => 'PENDING',
                    ],
                    [
                        'match' => 'PSG vs Olympique Lyonnais',
                        'championship' => 'Ligue 1 - France',
                        'match_time' => '20:45',
                        'tip' => 'Les deux équipes marquent (BTTS - Oui)',
                        'odds' => 1.80,
                        'status' => 'PENDING',
                    ],
                    [
                        'match' => 'Bayern Munich vs RB Leipzig',
                        'championship' => 'Bundesliga - Allemagne',
                        'match_time' => '18:30',
                        'tip' => 'Plus de 2.5 buts dans le match',
                        'odds' => 1.75,
                        'status' => 'PENDING',
                    ],
                ],
                'analysis' => 'Combiné de 3 matchs sélectionnés par les algorithmes Frogazz : 1.65 × 1.80 × 1.75 = 5.18 de cote totale. Ratio sécurité/gain optimal !',
                'status' => 'PENDING',
                'image_url' => 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=600&q=80',
                'is_published' => true,
            ],
            [
                'title' => '🐸 COMBINÉ FROGAZZ CÔTE 5 DU MARDI (3 MATCHS)',
                'competition' => 'Europe - Combiné VIP Frogazz',
                'country' => 'Europe',
                'championship' => 'Combiné PL & Serie A',
                'match_date' => $now->copy()->addDay()->format('Y-m-d'),
                'match_time' => '16:30',
                'home_team' => 'Arsenal / Inter Milan / FC Porto',
                'away_team' => 'Chelsea / AC Milan / Benfica',
                'type' => 'COTE_5',
                'odds' => 5.04,
                'confidence' => 5,
                'selections_json' => [
                    [
                        'match' => 'Arsenal vs Chelsea',
                        'championship' => 'Premier League - Angleterre',
                        'match_time' => '16:30',
                        'tip' => 'Victoire Arsenal & Plus de 1.5 buts',
                        'odds' => 1.80,
                        'status' => 'PENDING',
                    ],
                    [
                        'match' => 'Inter Milan vs AC Milan',
                        'championship' => 'Serie A - Italie',
                        'match_time' => '20:45',
                        'tip' => 'Victoire Inter Milan (DNB 1)',
                        'odds' => 1.75,
                        'status' => 'PENDING',
                    ],
                    [
                        'match' => 'FC Porto vs Benfica',
                        'championship' => 'Liga Portugal',
                        'match_time' => '21:00',
                        'tip' => 'Plus de 1.5 buts en 2e mi-temps',
                        'odds' => 1.60,
                        'status' => 'PENDING',
                    ],
                ],
                'analysis' => 'Deuxième ticket Côte 5 Frogazz de la semaine. Chaque match a été analysé individuellement avec nos statistiques.',
                'status' => 'PENDING',
                'image_url' => 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=600&q=80',
                'is_published' => true,
            ],
            [
                'title' => '👑 COMBINÉ FROGAZZ CÔTE 10 - SAUT DES CHAMPIONS (4 MATCHS)',
                'competition' => 'Europe - Combiné VIP Frogazz',
                'country' => 'Europe',
                'championship' => 'Combiné Champions & Europa',
                'match_date' => $now->copy()->addDays(2)->format('Y-m-d'),
                'match_time' => '18:30',
                'home_team' => 'Man City / Juventus / Dortmund / Barça',
                'away_team' => 'Aston Villa / Naples / Francfort / Atl. Madrid',
                'type' => 'COTE_10',
                'odds' => 10.45,
                'confidence' => 4,
                'selections_json' => [
                    [
                        'match' => 'Manchester City vs Aston Villa',
                        'championship' => 'Premier League - Angleterre',
                        'match_time' => '18:30',
                        'tip' => 'Victoire Man City & Haaland Buteur',
                        'odds' => 1.85,
                        'status' => 'PENDING',
                    ],
                    [
                        'match' => 'Juventus vs Naples',
                        'championship' => 'Serie A - Italie',
                        'match_time' => '20:45',
                        'tip' => 'Moins de 3.5 buts dans le match',
                        'odds' => 1.70,
                        'status' => 'PENDING',
                    ],
                    [
                        'match' => 'Borussia Dortmund vs Eintracht Francfort',
                        'championship' => 'Bundesliga - Allemagne',
                        'match_time' => '17:30',
                        'tip' => 'Victoire Dortmund (1)',
                        'odds' => 1.80,
                        'status' => 'PENDING',
                    ],
                    [
                        'match' => 'FC Barcelone vs Atletico Madrid',
                        'championship' => 'La Liga - Espagne',
                        'match_time' => '21:00',
                        'tip' => 'Les deux équipes marquent (Oui)',
                        'odds' => 1.85,
                        'status' => 'PENDING',
                    ],
                ],
                'analysis' => 'Combiné de 4 matchs pour atteindre notre cote 10 exclusive Frogazz. Notre équipe conseille d\'allouer 2% de bankroll.',
                'status' => 'PENDING',
                'image_url' => 'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?w=600&q=80',
                'is_published' => true,
            ],
            [
                'title' => '💎 MÉGA COMBINÉ FROGAZZ SEMAINE VIP (6 MATCHS)',
                'competition' => 'Ligue des Champions',
                'country' => 'Europe',
                'championship' => 'Ligue des Champions',
                'match_date' => $now->copy()->addDays(3)->format('Y-m-d'),
                'match_time' => '21:00',
                'home_team' => 'Sélection 6 Équipes Européennes',
                'away_team' => 'Ligue des Champions',
                'type' => 'COTE_50',
                'odds' => 54.20,
                'confidence' => 4,
                'selections_json' => [
                    ['match' => 'Real Madrid vs Benfica', 'championship' => 'UCL', 'match_time' => '21:00', 'tip' => 'Victoire Real Madrid', 'odds' => 1.60, 'status' => 'PENDING'],
                    ['match' => 'Manchester City vs Porto', 'championship' => 'UCL', 'match_time' => '21:00', 'tip' => 'Victoire City -1.5', 'odds' => 1.75, 'status' => 'PENDING'],
                    ['match' => 'Bayern Munich vs Celtic', 'championship' => 'UCL', 'match_time' => '21:00', 'tip' => 'Plus de 3.5 buts', 'odds' => 1.80, 'status' => 'PENDING'],
                    ['match' => 'Liverpool vs Galatasaray', 'championship' => 'UCL', 'match_time' => '21:00', 'tip' => 'Victoire Liverpool (1)', 'odds' => 1.55, 'status' => 'PENDING'],
                    ['match' => 'Inter Milan vs Shakhtar', 'championship' => 'UCL', 'match_time' => '21:00', 'tip' => 'Inter Milan sans encaisser', 'odds' => 2.05, 'status' => 'PENDING'],
                    ['match' => 'Arsenal vs PSV Eindhoven', 'championship' => 'UCL', 'match_time' => '21:00', 'tip' => 'Arsenal gagne les deux mi-temps', 'odds' => 3.40, 'status' => 'PENDING'],
                ],
                'analysis' => 'Notre combiné phare de la semaine réunit 6 sélections européennes pour une cote finale multipliée de 54.20. Réservé aux abonnés VIP Frogazz.',
                'status' => 'PENDING',
                'image_url' => 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=600&q=80',
                'is_published' => true,
            ],
            [
                'title' => '📈 MONTANTE FROGAZZ ÉTAPE 1 : Inter Milan vs AS Roma',
                'competition' => 'Serie A',
                'country' => 'Italie',
                'championship' => 'Serie A',
                'match_date' => $now->copy()->format('Y-m-d'),
                'match_time' => '20:45',
                'home_team' => 'Inter Milan',
                'away_team' => 'AS Roma',
                'type' => 'MONTANTE',
                'odds' => 1.85,
                'confidence' => 5,
                'selections_json' => [
                    [
                        'match' => 'Inter Milan vs AS Roma',
                        'championship' => 'Serie A - Italie',
                        'match_time' => '20:45',
                        'tip' => 'Victoire Inter Milan (Remboursé si match nul)',
                        'odds' => 1.85,
                        'status' => 'PENDING',
                    ],
                ],
                'analysis' => 'Étape 1 de notre montante en 5 jours. Victoire de l\'Inter Milan (remboursé si match nul).',
                'status' => 'PENDING',
                'image_url' => 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=600&q=80',
                'is_published' => true,
            ],
            [
                'title' => '📈 MONTANTE FROGAZZ ÉTAPE 2 : Juventus vs Naples',
                'competition' => 'Serie A',
                'country' => 'Italie',
                'championship' => 'Serie A',
                'match_date' => $now->copy()->addDay()->format('Y-m-d'),
                'match_time' => '20:45',
                'home_team' => 'Juventus',
                'away_team' => 'Naples',
                'type' => 'MONTANTE',
                'odds' => 1.95,
                'confidence' => 5,
                'selections_json' => [
                    [
                        'match' => 'Juventus vs Naples',
                        'championship' => 'Serie A - Italie',
                        'match_time' => '20:45',
                        'tip' => 'Double chance 1X & Plus de 1.5 buts',
                        'odds' => 1.95,
                        'status' => 'PENDING',
                    ],
                ],
                'analysis' => 'Étape 2 de la montante : Double chance 1X + Plus de 1.5 buts dans la rencontre.',
                'status' => 'PENDING',
                'image_url' => 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=600&q=80',
                'is_published' => true,
            ],
            [
                'title' => '🐸 COMBINÉ FROGAZZ CÔTE 5 (HISTORIQUE GAGNÉ - 3 MATCHS)',
                'competition' => 'Premier League',
                'country' => 'Angleterre',
                'championship' => 'Combiné Premier League',
                'match_date' => $now->copy()->subDays(2)->format('Y-m-d'),
                'match_time' => '17:30',
                'home_team' => 'Liverpool / Newcastle / Tottenham',
                'away_team' => 'Chelsea / Everton / Fulham',
                'type' => 'COTE_5',
                'odds' => 5.10,
                'confidence' => 5,
                'selections_json' => [
                    ['match' => 'Liverpool vs Chelsea', 'championship' => 'Premier League', 'match_time' => '17:30', 'tip' => 'Victoire Liverpool (3-1)', 'odds' => 1.75, 'status' => 'WON'],
                    ['match' => 'Newcastle vs Everton', 'championship' => 'Premier League', 'match_time' => '15:00', 'tip' => 'Victoire Newcastle (2-0)', 'odds' => 1.70, 'status' => 'WON'],
                    ['match' => 'Tottenham vs Fulham', 'championship' => 'Premier League', 'match_time' => '15:00', 'tip' => 'Plus de 2.5 buts (2-1)', 'odds' => 1.72, 'status' => 'WON'],
                ],
                'analysis' => 'Combiné Côte 5 gagnant à 100% ! Les 3 matchs du ticket Frogazz ont été validés sans accroc.',
                'status' => 'WON',
                'image_url' => 'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?w=600&q=80',
                'is_published' => true,
            ],
        ];

        foreach ($predictions as $predData) {
            Prediction::create($predData);
        }

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
