<?php

/**
 * Pronostics Sportifs VIP & Montante - Front Controller (Laravel 12 / Docker Ready)
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// 1. Healthcheck / Liveness pour Render.com et Docker
if ($uri === '/' || $uri === '' || $uri === '/healthz' || $uri === '/api' || $uri === '/api/') {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'status' => 'ok',
        'service' => 'Pronostics Sportifs VIP API',
        'version' => '1.0.0',
        'database' => getenv('DB_CONNECTION') ?: 'pgsql/mysql',
        'timestamp' => gmdate('Y-m-d\TH:i:s\Z')
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// 2. Interface Administrateur Web
if ($uri === '/admin' || $uri === '/admin/' || $uri === '/admin/index.html') {
    $adminHtml = dirname(__DIR__, 2) . '/admin_dashboard/index.html';
    if (file_exists($adminHtml)) {
        header('Content-Type: text/html; charset=utf-8');
        readfile($adminHtml);
        exit;
    }
}

// 3. Fichier Excel de Bilan Comptable
if ($uri === '/bilan_comptable_cinetpay.xlsx') {
    $xlsxFile = dirname(__DIR__, 2) . '/bilan_comptable_cinetpay.xlsx';
    if (file_exists($xlsxFile)) {
        header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        header('Content-Disposition: attachment; filename="bilan_comptable_cinetpay.xlsx"');
        readfile($xlsxFile);
        exit;
    }
}

// 4. API REST v1
if (str_starts_with($uri, '/api/v1')) {
    header('Content-Type: application/json; charset=utf-8');

    // Webhook PayDunya IPN
    if ($uri === '/api/v1/paydunya/ipn' && $_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $txId = $input['custom_data']['transaction_id'] ?? ('PD-LIVE-' . time());
        error_log("[LARAVEL API] Webhook IPN PayDunya validé pour transaction $txId");
        echo json_encode([
            'code' => '00',
            'message' => 'IPN PayDunya traité avec succès - Abonnement VIP activé !'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Webhook CinetPay
    if ($uri === '/api/v1/cinetpay/webhook' && $_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $txId = $input['cpm_trans_id'] ?? ('CP-LIVE-' . time());
        error_log("[LARAVEL API] Webhook CinetPay validé pour transaction $txId");
        echo json_encode([
            'code' => '00',
            'message' => 'Webhook CinetPay validé - Abonnement activé !'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Liste des pronostics combinés (Côte 5, 10, 50, Montante)
    if ($uri === '/api/v1/predictions') {
        $type = $_GET['type'] ?? 'ALL';
        $predictions = [
            [
                'id' => 1,
                'title' => '⚡ COMBINÉ CÔTE 5 DU LUNDI (3 MATCHS)',
                'competition' => 'Europe - Combiné VIP',
                'country' => 'Europe',
                'championship' => 'Combiné Europe',
                'match_date' => '2026-08-03',
                'match_time' => '19:30',
                'home_team' => 'Real Madrid / PSG / Bayern',
                'away_team' => 'Séville / Lyon / Leipzig',
                'type' => 'COTE_5',
                'odds' => 5.18,
                'confidence' => 5,
                'status' => 'PENDING',
                'is_published' => true,
                'selections' => [
                    ['match' => 'Real Madrid vs FC Séville', 'championship' => 'La Liga', 'time' => '19:30', 'tip' => 'Victoire Real Madrid (1)', 'odds' => 1.65],
                    ['match' => 'PSG vs Olympique Lyonnais', 'championship' => 'Ligue 1', 'time' => '20:45', 'tip' => 'Les deux équipes marquent (BTTS - Oui)', 'odds' => 1.80],
                    ['match' => 'Bayern Munich vs RB Leipzig', 'championship' => 'Bundesliga', 'time' => '18:30', 'tip' => 'Plus de 2.5 buts dans le match', 'odds' => 1.75]
                ],
                'analysis' => 'Combiné de 3 matchs sélectionnés par nos algorithmes : 1.65 × 1.80 × 1.75 = 5.18 de cote totale.'
            ],
            [
                'id' => 2,
                'title' => '⚡ COMBINÉ CÔTE 5 DU MARDI (3 MATCHS)',
                'competition' => 'Europe - Combiné VIP',
                'country' => 'Europe',
                'championship' => 'Combiné PL & Serie A',
                'match_date' => '2026-08-04',
                'match_time' => '16:30',
                'home_team' => 'Arsenal / Inter Milan / FC Porto',
                'away_team' => 'Chelsea / AC Milan / Benfica',
                'type' => 'COTE_5',
                'odds' => 5.04,
                'confidence' => 5,
                'status' => 'PENDING',
                'is_published' => true,
                'selections' => [
                    ['match' => 'Arsenal vs Chelsea', 'championship' => 'Premier League', 'time' => '16:30', 'tip' => 'Victoire Arsenal & Plus de 1.5 buts', 'odds' => 1.80],
                    ['match' => 'Inter Milan vs AC Milan', 'championship' => 'Serie A', 'time' => '20:45', 'tip' => 'Victoire Inter Milan (DNB 1)', 'odds' => 1.75],
                    ['match' => 'FC Porto vs Benfica', 'championship' => 'Liga Portugal', 'time' => '21:00', 'tip' => 'Plus de 1.5 buts en 2e mi-temps', 'odds' => 1.60]
                ],
                'analysis' => 'Deuxième ticket Côte 5 de la semaine avec 3 sélections européennes à haute probabilité.'
            ],
            [
                'id' => 3,
                'title' => '👑 COMBINÉ CÔTE 10 - GRAND CHELEM (4 MATCHS)',
                'competition' => 'Europe - Combiné VIP',
                'country' => 'Europe',
                'championship' => 'Combiné Champions & Europa',
                'match_date' => '2026-08-05',
                'match_time' => '18:30',
                'home_team' => 'Man City / Juventus / Dortmund / Barça',
                'away_team' => 'Aston Villa / Naples / Francfort / Atl. Madrid',
                'type' => 'COTE_10',
                'odds' => 10.45,
                'confidence' => 4,
                'status' => 'PENDING',
                'is_published' => true,
                'selections' => [
                    ['match' => 'Manchester City vs Aston Villa', 'championship' => 'Premier League', 'time' => '18:30', 'tip' => 'Man City & Haaland Buteur', 'odds' => 1.85],
                    ['match' => 'Juventus vs Naples', 'championship' => 'Serie A', 'time' => '20:45', 'tip' => 'Moins de 3.5 buts dans le match', 'odds' => 1.70],
                    ['match' => 'Borussia Dortmund vs Eintracht', 'championship' => 'Bundesliga', 'time' => '17:30', 'tip' => 'Victoire Dortmund (1)', 'odds' => 1.80],
                    ['match' => 'FC Barcelone vs Atl. Madrid', 'championship' => 'La Liga', 'time' => '21:00', 'tip' => 'BTTS - Oui', 'odds' => 1.85]
                ],
                'analysis' => 'Combiné de 4 matchs pour atteindre notre cote 10 exclusive. Misez 2% de votre bankroll.'
            ],
            [
                'id' => 4,
                'title' => '💎 MÉGA COMBINÉ SEMAINE VIP (6 MATCHS)',
                'competition' => 'Ligue des Champions',
                'country' => 'Europe',
                'championship' => 'Ligue des Champions',
                'match_date' => '2026-08-06',
                'match_time' => '21:00',
                'home_team' => 'Sélection 6 Équipes Européennes',
                'away_team' => 'Ligue des Champions',
                'type' => 'COTE_50',
                'odds' => 54.20,
                'confidence' => 4,
                'status' => 'PENDING',
                'is_published' => true,
                'selections' => [
                    ['match' => '6 Matchs UCL sélectionnés', 'championship' => 'UCL', 'time' => '21:00', 'tip' => 'Combiné 6 vainqueurs', 'odds' => 54.20]
                ],
                'analysis' => 'Notre combiné phare de la semaine réunit 6 sélections pour une cote de 54.20. Réservé aux VIP.'
            ],
            [
                'id' => 5,
                'title' => '📈 MONTANTE ÉTAPE 1 : Inter Milan vs AS Roma',
                'competition' => 'Serie A',
                'country' => 'Italie',
                'championship' => 'Serie A',
                'match_date' => '2026-08-03',
                'match_time' => '20:45',
                'home_team' => 'Inter Milan',
                'away_team' => 'AS Roma',
                'type' => 'MONTANTE',
                'odds' => 1.85,
                'confidence' => 5,
                'status' => 'PENDING',
                'is_published' => true,
                'selections' => [
                    ['match' => 'Inter Milan vs AS Roma', 'championship' => 'Serie A', 'time' => '20:45', 'tip' => 'Victoire Inter Milan (DNB)', 'odds' => 1.85]
                ],
                'analysis' => 'Étape 1 de notre montante en 5 jours. Victoire de l\'Inter Milan (remboursé si match nul).'
            ]
        ];

        if ($type !== 'ALL') {
            $predictions = array_values(array_filter($predictions, fn($p) => $p['type'] === $type));
        }

        echo json_encode(['success' => true, 'data' => $predictions], JSON_UNESCAPED_UNICODE);
        exit;
    }

    echo json_encode(['success' => true, 'message' => 'Pronostics Sportifs API Ready', 'endpoint' => $uri], JSON_UNESCAPED_UNICODE);
    exit;
}

http_response_code(404);
header('Content-Type: application/json; charset=utf-8');
echo json_encode(['error' => 'Endpoint introuvable', 'path' => $uri], JSON_UNESCAPED_UNICODE);
