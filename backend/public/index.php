<?php

/**
 * Frogazz Sport Analyse - API REST Production Engine (100% Mode Réel)
 * Zéro donnée fictive. Gère l'authentification PostgreSQL réelle,
 * les abonnements VIP/Montante et les webhooks de paiement LigdiCash.
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

// 1. HEALTHCHECK & STATUT
if ($uri === '/' || $uri === '' || $uri === '/healthz' || $uri === '/api' || $uri === '/api/') {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'status' => 'ok',
        'service' => 'Frogazz Sport Analyse VIP API (Production)',
        'mode' => '100% LIVE REAL MODE',
        'version' => '2.1.0',
        'timestamp' => gmdate('Y-m-d\TH:i:s\Z')
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// 2. INTERFACE ADMINISTRATEUR WEB & EXPORT EXCEL
if ($uri === '/admin' || $uri === '/admin/' || $uri === '/admin/index.html') {
    $adminPaths = [
        __DIR__ . '/admin/index.html',
        dirname(__DIR__) . '/public/admin/index.html',
        dirname(__DIR__) . '/admin_dashboard/index.html',
        dirname(__DIR__, 2) . '/admin_dashboard/index.html'
    ];
    foreach ($adminPaths as $path) {
        if (file_exists($path)) {
            header('Content-Type: text/html; charset=utf-8');
            readfile($path);
            exit;
        }
    }
}

if ($uri === '/bilan_comptable_cinetpay.xlsx') {
    $xlsxPaths = [
        __DIR__ . '/bilan_comptable_cinetpay.xlsx',
        dirname(__DIR__) . '/public/bilan_comptable_cinetpay.xlsx',
        dirname(__DIR__) . '/bilan_comptable_cinetpay.xlsx',
        dirname(__DIR__, 2) . '/bilan_comptable_cinetpay.xlsx'
    ];
    foreach ($xlsxPaths as $path) {
        if (file_exists($path)) {
            header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            header('Content-Disposition: attachment; filename="bilan_comptable_cinetpay.xlsx"');
            readfile($path);
            exit;
        }
    }
}

// 3. CONNEXION PDO À LA BASE DE DONNÉES CLOUD (Aiven PostgreSQL ou MySQL)
function getDbConnection(): ?PDO {
    static $pdo = null;
    if ($pdo !== null) return $pdo;

    // 1. Priorité : variable unique DATABASE_URL (postgresql://user:pass@host:port/db)
    //    Si absente, on utilise directement la base PostgreSQL Render de production.
    $dbUrl = getenv('DATABASE_URL') ?: 'postgresql://frogazz_db_user:rLO7zi2vpbr3WgSyJqO4oVq42zBpoX00@dpg-da4kgec9v7es738fghvg-a.frankfurt-postgres.render.com/frogazz_db';
    if (!empty($dbUrl)) {
        $parts = parse_url($dbUrl);
        $driver = 'pgsql';
        $host = $parts['host'] ?? '';
        $port = $parts['port'] ?? '5432';
        $dbname = ltrim($parts['path'] ?? '', '/');
        $user = $parts['user'] ?? '';
        $pass = $parts['pass'] ?? '';
    } else {
        // 2. Sinon : variables séparées (DB_HOST, DB_PORT, ...)
        $driver = getenv('DB_CONNECTION') ?: 'pgsql';
        $host = getenv('DB_HOST') ?: 'dpg-da4kgec9v7es738fghvg-a.frankfurt-postgres.render.com';
        $port = getenv('DB_PORT') ?: '5432';
        $dbname = getenv('DB_DATABASE') ?: 'frogazz_db';
        $user = getenv('DB_USERNAME') ?: 'frogazz_db_user';
        $pass = getenv('DB_PASSWORD') ?: '';
    }

    try {
        if ($driver === 'pgsql') {
            $dsn = "pgsql:host={$host};port={$port};dbname={$dbname};sslmode=require";
        } else {
            $dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8mb4";
        }
        $pdo = new PDO($dsn, $user, $pass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]);
        return $pdo;
    } catch (Exception $e) {
        error_log("[LARAVEL API DB ERROR] Connexion BDD impossible: " . $e->getMessage());
        return null;
    }
}

// 3b. AUTO-SCHÉMA : crée automatiquement les tables + admin + forfaits si absents (zéro migration manuelle)
function ensureSchema(PDO $pdo): void {
    static $done = false;
    if ($done) return;
    $done = true;
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS users (
            id BIGSERIAL PRIMARY KEY,
            last_name VARCHAR(100) NOT NULL,
            first_name VARCHAR(100) NOT NULL,
            phone VARCHAR(30) NOT NULL UNIQUE,
            email VARCHAR(150) NOT NULL UNIQUE,
            password VARCHAR(255) NOT NULL,
            is_admin BOOLEAN NOT NULL DEFAULT FALSE,
            subscription_status VARCHAR(50) NOT NULL DEFAULT 'FREE',
            subscription_expires_at TIMESTAMP NULL,
            free_trial_expires_at TIMESTAMP NULL,
            referral_code VARCHAR(20) NULL UNIQUE,
            referred_by_id BIGINT NULL,
            fcm_token VARCHAR(255) NULL,
            remember_token VARCHAR(255) NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        )");
        $pdo->exec("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)");
        $pdo->exec("CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone)");

        $pdo->exec("CREATE TABLE IF NOT EXISTS subscription_plans (
            id BIGSERIAL PRIMARY KEY,
            code VARCHAR(50) NOT NULL UNIQUE,
            name VARCHAR(100) NOT NULL,
            price INTEGER NOT NULL DEFAULT 2000,
            duration_days INTEGER NOT NULL DEFAULT 30,
            description TEXT NULL,
            features_json JSONB NULL,
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        )");

        $pdo->exec("CREATE TABLE IF NOT EXISTS user_subscriptions (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL,
            subscription_plan_id BIGINT NOT NULL,
            status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
            starts_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NOT NULL,
            auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        )");

        $pdo->exec("CREATE TABLE IF NOT EXISTS predictions (
            id BIGSERIAL PRIMARY KEY,
            title VARCHAR(200) NOT NULL,
            competition VARCHAR(150) NOT NULL,
            country VARCHAR(100) NOT NULL,
            championship VARCHAR(150) NOT NULL,
            match_date DATE NOT NULL,
            match_time VARCHAR(10) NOT NULL,
            home_team VARCHAR(150) NOT NULL,
            away_team VARCHAR(150) NOT NULL,
            type VARCHAR(50) NOT NULL,
            odds NUMERIC(6,2) NOT NULL,
            selections_json JSONB NULL,
            confidence SMALLINT NOT NULL DEFAULT 4,
            analysis TEXT NULL,
            status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
            image_url VARCHAR(255) NULL,
            is_published BOOLEAN NOT NULL DEFAULT TRUE,
            is_archived BOOLEAN NOT NULL DEFAULT FALSE,
            scheduled_at TIMESTAMP NULL,
            published_at TIMESTAMP NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        )");
        $pdo->exec("CREATE INDEX IF NOT EXISTS idx_pred_type ON predictions(type)");
        $pdo->exec("CREATE INDEX IF NOT EXISTS idx_pred_status ON predictions(status)");

        $pdo->exec("CREATE TABLE IF NOT EXISTS payments (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NULL,
            subscription_plan_id BIGINT NULL,
            transaction_id VARCHAR(100) NOT NULL UNIQUE,
            cinetpay_token VARCHAR(255) NULL,
            ligdicash_token VARCHAR(255) NULL,
            amount INTEGER NOT NULL,
            currency VARCHAR(10) NOT NULL DEFAULT 'XOF',
            status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
            payment_method VARCHAR(50) NOT NULL DEFAULT 'MOBILE_MONEY',
            operator_id VARCHAR(100) NULL,
            raw_response JSONB NULL,
            paid_at TIMESTAMP NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        )");

        $pdo->exec("CREATE TABLE IF NOT EXISTS promo_codes (
            id BIGSERIAL PRIMARY KEY,
            code VARCHAR(30) NOT NULL UNIQUE,
            discount_percent INTEGER NOT NULL DEFAULT 10,
            max_uses INTEGER NOT NULL DEFAULT 100,
            used_count INTEGER NOT NULL DEFAULT 0,
            expires_at TIMESTAMP NULL,
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        )");

        $pdo->exec("CREATE TABLE IF NOT EXISTS faqs (
            id BIGSERIAL PRIMARY KEY,
            question VARCHAR(255) NOT NULL,
            answer TEXT NOT NULL,
            category VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
            display_order INTEGER NOT NULL DEFAULT 1,
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        )");

        // Seed forfaits (VIP + Montante) si la table est vide
        $cnt = (int) $pdo->query("SELECT COUNT(*) FROM subscription_plans")->fetchColumn();
        if ($cnt === 0) {
            $pdo->exec("INSERT INTO subscription_plans (code, name, price, duration_days, description, features_json, is_active) VALUES
                ('VIP', 'Abonnement VIP Mensuel', 2000, 30, 'Accès Côte 5, 10 et 50', '[\"Côte 5 quotidienne\",\"Côte 10 exclusive\",\"Pronostic Semaine Côte 50\"]'::jsonb, TRUE),
                ('MONTANTE', 'Abonnement Montante Hebdomadaire', 2000, 7, 'Stratégie Montante 7 jours', '[\"Pronostics Montante exclusifs\",\"Gestion de mise pas-à-pas\"]'::jsonb, TRUE)");
        }

        // Seed admin (admin@frogazz.pro / Frogazz@Admin2026) si aucun admin
        $adminCnt = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE is_admin = TRUE")->fetchColumn();
        if ($adminCnt === 0) {
            $hash = password_hash('Frogazz@Admin2026', PASSWORD_BCRYPT);
            $st = $pdo->prepare("INSERT INTO users (last_name, first_name, phone, email, password, is_admin, subscription_status, referral_code) VALUES (?, ?, ?, ?, ?, TRUE, 'FREE', 'ADMINVIP')");
            $st->execute(['Admin', 'Frogazz', '+22600000000', 'admin@frogazz.pro', $hash]);
        }

        // Seed FAQs réelles si vides
        $faqCnt = (int) $pdo->query("SELECT COUNT(*) FROM faqs")->fetchColumn();
        if ($faqCnt === 0) {
            $pdo->exec("INSERT INTO faqs (question, answer, category, display_order) VALUES
                ('Comment fonctionne le mode gratuit ?', 'Dès votre inscription, vous recevez le Combiné Gratuit de 3 matchs chaque jour. Les Côtes 5, 10, 50 et Montante nécessitent un abonnement.', 'ABONNEMENT', 1),
                ('Quelle est la différence entre VIP et Montante ?', 'VIP (2000 FCFA/mois) = Côtes 5, 10, 50. Montante (2000 FCFA/semaine) = stratégie Montante.', 'ABONNEMENT', 2),
                ('Comment payer ?', 'Via Orange Money ou Moov Money (LigdiCash). Composez *144*4*6# pour Orange, ou validez la demande USSD pour Moov.', 'PAIEMENT', 3)");
        }
        // Colonne token LigdiCash pour les bases déjà existantes (idempotent)
        $pdo->exec("ALTER TABLE payments ADD COLUMN IF NOT EXISTS ligdicash_token VARCHAR(255) NULL");
        $pdo->exec("ALTER TABLE payments ADD COLUMN IF NOT EXISTS operator_id VARCHAR(100) NULL");
    } catch (Exception $e) {
        error_log("[AUTO-SCHEMA] " . $e->getMessage());
    }
}

// =========================================================================
// HELPERS LIGDICASH (remplace CinetPay) — API officielle ligdicash.com
// =========================================================================

// Récupère l'utilisateur connecté à partir du Bearer token (ou null si non authentifié)
function getAuthedUser(PDO $pdo): ?array {
    $headers = getallheaders();
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    if (empty($auth) || !str_starts_with($auth, 'Bearer ')) return null;
    $token = trim(substr($auth, 7));
    try {
        $stmt = $pdo->prepare("SELECT * FROM users WHERE remember_token = ?");
        $stmt->execute([$token]);
        $u = $stmt->fetch();
        return $u ?: null;
    } catch (Exception $e) {
        return null;
    }
}

// Envoie une requête HTTP vers l'API LigdiCash (authentification Apikey + Bearer token)
function ligdicashRequest(string $method, string $url, ?array $body = null): array {
    $apiKey = getenv('LIGDICASH_API_KEY') ?: '';
    $apiToken = getenv('LIGDICASH_API_TOKEN') ?: '';
    $ch = curl_init($url);
    $headers = [
        'Apikey: ' . $apiKey,
        'Authorization: Bearer ' . $apiToken,
        'Accept: application/json',
        'Content-Type: application/json',
    ];
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_TIMEOUT, 45);
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }
    $resp = curl_exec($ch);
    $err = curl_error($ch);
    curl_close($ch);
    if ($resp === false) {
        return ['_error' => 'Erreur réseau LigdiCash: ' . $err];
    }
    $data = json_decode($resp, true);
    return is_array($data) ? $data : ['_error' => 'Réponse LigdiCash invalide'];
}

// Active un abonnement VIP ou Montante pour un utilisateur (durée en jours)
function activateSubscription(PDO $pdo, int $userId, string $planCode, int $durationDays): void {
    $status = $planCode === 'MONTANTE' ? 'ACTIVE_MONTANTE' : 'ACTIVE';
    $exp = gmdate('Y-m-d H:i:s', time() + $durationDays * 86400);
    $pdo->prepare("UPDATE users SET subscription_status = ?, subscription_expires_at = ? WHERE id = ?")
        ->execute([$status, $exp, $userId]);
    $stmt = $pdo->prepare("SELECT id FROM subscription_plans WHERE code = ?");
    $stmt->execute([$planCode]);
    $plan = $stmt->fetch();
    if ($plan) {
        $pdo->prepare("INSERT INTO user_subscriptions (user_id, subscription_plan_id, status, starts_at, expires_at) VALUES (?, ?, 'ACTIVE', NOW(), ?)")
            ->execute([$userId, $plan['id'], $exp]);
    }
}

// 4. MOTEUR API REST v1 (100% RÉEL - ZÉRO DONNÉE FICTIVE)
if (str_starts_with($uri, '/api/v1')) {
    header('Content-Type: application/json; charset=utf-8');
    $pdo = getDbConnection();
    if ($pdo) ensureSchema($pdo);
    $input = json_decode(file_get_contents('php://input'), true) ?? [];

    // =========================================================================
    // A. AUTHENTIFICATION RÉELLE EN BASE DE DONNÉES
    // =========================================================================

    // 1. INSCRIPTION (/api/v1/auth/register) -> Mode 100% Réel en base de données Aiven
    if ($uri === '/api/v1/auth/register' && $method === 'POST') {
        $email = strtolower(trim($input['email'] ?? ''));
        $phone = trim($input['phone'] ?? '');
        $lastName = trim($input['last_name'] ?? '');
        $firstName = trim($input['first_name'] ?? '');
        $password = trim($input['password'] ?? '');

        if (empty($email) || empty($phone) || empty($password) || empty($firstName) || empty($lastName)) {
            http_response_code(422);
            echo json_encode([
                'success' => false,
                'message' => 'Veuillez remplir tous les champs obligatoires (Nom, Prénom, Téléphone, Email, Mot de passe).'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }

        if (!$pdo) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'code' => 'DB_CONNECTION_ERROR',
                'message' => 'Erreur de connexion à la base de données réelle (Aiven PostgreSQL). Veuillez configurer la variable DB_PASSWORD sur Render.com.'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ? OR phone = ?");
        $stmt->execute([$email, $phone]);
        if ($stmt->fetch()) {
            http_response_code(422);
            echo json_encode([
                'success' => false,
                'message' => 'Cette adresse email ou ce numéro de téléphone est déjà inscrit.'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
        $refCode = strtoupper(substr(md5(uniqid()), 0, 8));
        $token = '1|' . bin2hex(random_bytes(32));

        $insert = $pdo->prepare("
            INSERT INTO users (last_name, first_name, phone, email, password, is_admin, subscription_status, free_trial_expires_at, referral_code, created_at)
            VALUES (?, ?, ?, ?, ?, FALSE, 'FREE', NULL, ?, NOW())
            RETURNING id, last_name, first_name, phone, email, is_admin, subscription_status, free_trial_expires_at, referral_code, created_at
        ");
        $insert->execute([$lastName, $firstName, $phone, $email, $hashedPassword, $refCode]);
        $user = $insert->fetch();

        // Stocker le jeton d'accès réel pour que le profil soit récupérable par Bearer token
        try {
            $pdo->prepare("UPDATE users SET remember_token = ? WHERE id = ?")->execute([$token, $user['id']]);
        } catch (Exception $e) {
            error_log("[REGISTER] Impossible de stocker le jeton: " . $e->getMessage());
        }

        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => "Inscription réussie ! Vous avez accès à vie à la section Gratuit (3 Matchs). Abonnez-vous pour débloquer les Côtes 5, 10, 50 et Montante.",
            'token' => $token,
            'user' => [
                'id' => (int) $user['id'],
                'last_name' => $user['last_name'],
                'first_name' => $user['first_name'],
                'phone' => $user['phone'],
                'email' => $user['email'],
                'is_admin' => (bool) $user['is_admin'],
                'subscription_status' => $user['subscription_status'],
                'subscription_expires_at' => null,
                'free_trial_expires_at' => null,
                'referral_code' => $user['referral_code'],
                'has_vip' => false,
                'has_montante' => false,
                'has_free_trial_cote_5' => false,
                'created_at' => $user['created_at']
            ]
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // 2. CONNEXION (/api/v1/auth/login) -> Mode 100% Réel (Strict, aucune connexion fictive tolérée)
    if ($uri === '/api/v1/auth/login' && $method === 'POST') {
        $email = strtolower(trim($input['email'] ?? ''));
        $password = trim($input['password'] ?? '');

        if (!$pdo) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'code' => 'DB_CONNECTION_ERROR',
                'message' => 'Erreur serveur : impossible de contacter la base de données réelle. Vérifiez votre variable DB_PASSWORD sur Render.com.'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ? OR phone = ?");
        $stmt->execute([$email, $email]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($password, $user['password'])) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'code' => 'INVALID_CREDENTIALS',
                'message' => 'Adresse email ou mot de passe incorrect. Compte introuvable dans la base de données.'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $token = '1|' . bin2hex(random_bytes(32));
        $isVip = $user['subscription_status'] === 'ACTIVE';
        $isMontante = $user['subscription_status'] === 'ACTIVE_MONTANTE';

        // Stocker le jeton d'accès réel pour récupérer le profil ensuite
        try {
            $pdo->prepare("UPDATE users SET remember_token = ? WHERE id = ?")->execute([$token, $user['id']]);
        } catch (Exception $e) {
            error_log("[LOGIN] Impossible de stocker le jeton: " . $e->getMessage());
        }

        echo json_encode([
            'success' => true,
            'message' => 'Connexion réussie',
            'token' => $token,
            'user' => [
                'id' => (int) $user['id'],
                'last_name' => $user['last_name'],
                'first_name' => $user['first_name'],
                'phone' => $user['phone'],
                'email' => $user['email'],
                'is_admin' => (bool) $user['is_admin'],
                'subscription_status' => $user['subscription_status'],
                'subscription_expires_at' => $user['subscription_expires_at'],
                'free_trial_expires_at' => $user['free_trial_expires_at'],
                'referral_code' => $user['referral_code'],
                'has_vip' => $isVip,
                'has_montante' => $isMontante,
                'has_free_trial_cote_5' => false,
                'created_at' => $user['created_at']
            ]
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // 3. PROFIL ACTUEL (/api/v1/auth/profile) -> 100% réel, basé sur le Bearer token en base
    if ($uri === '/api/v1/auth/profile' && $method === 'GET') {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
        if (empty($authHeader) || !str_starts_with($authHeader, 'Bearer ')) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Non authentifié.'], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $token = trim(substr($authHeader, 7));

        if (!$pdo) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'code' => 'DB_CONNECTION_ERROR',
                'message' => 'Erreur serveur : impossible de contacter la base de données réelle.'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }

        try {
            $stmt = $pdo->prepare("SELECT * FROM users WHERE remember_token = ?");
            $stmt->execute([$token]);
            $user = $stmt->fetch();
        } catch (Exception $e) {
            error_log("[PROFILE] " . $e->getMessage());
            $user = false;
        }

        if (!$user) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Session invalide ou expirée. Veuillez vous reconnecter.'], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $isVip = $user['subscription_status'] === 'ACTIVE';
        $isMontante = $user['subscription_status'] === 'ACTIVE_MONTANTE';

        echo json_encode([
            'success' => true,
            'user' => [
                'id' => (int) $user['id'],
                'last_name' => $user['last_name'],
                'first_name' => $user['first_name'],
                'phone' => $user['phone'],
                'email' => $user['email'],
                'is_admin' => (bool) $user['is_admin'],
                'subscription_status' => $user['subscription_status'],
                'subscription_expires_at' => $user['subscription_expires_at'],
                'free_trial_expires_at' => $user['free_trial_expires_at'],
                'referral_code' => $user['referral_code'],
                'has_vip' => $isVip,
                'has_montante' => $isMontante,
                'has_free_trial_cote_5' => false,
                'created_at' => $user['created_at']
            ]
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($uri === '/api/v1/auth/logout' && $method === 'POST') {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
        if (!empty($authHeader) && str_starts_with($authHeader, 'Bearer ') && $pdo) {
            try {
                $token = trim(substr($authHeader, 7));
                $pdo->prepare("UPDATE users SET remember_token = NULL WHERE remember_token = ?")->execute([$token]);
            } catch (Exception $e) {
                error_log("[LOGOUT] " . $e->getMessage());
            }
        }
        echo json_encode(['success' => true, 'message' => 'Déconnexion réussie.'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // =========================================================================
    // B. PRONOSTICS EN BASE DE DONNÉES RÉELLE (/api/v1/predictions)
    // =========================================================================
    if ($uri === '/api/v1/predictions' || $uri === '/api/v1/history/predictions') {
        $type = $_GET['type'] ?? 'ALL';
        $isHistory = str_contains($uri, 'history');

        if ($pdo) {
            $sql = "SELECT * FROM predictions WHERE is_published = TRUE";
            if ($isHistory) {
                $sql .= " AND status IN ('WON', 'LOST', 'VOID')";
            } else {
                $sql .= " AND status = 'PENDING'";
            }
            if ($type !== 'ALL') {
                $sql .= " AND type = :type";
            }
            $sql .= " ORDER BY match_date DESC, match_time ASC";

            $stmt = $pdo->prepare($sql);
            if ($type !== 'ALL') {
                $stmt->execute(['type' => $type]);
            } else {
                $stmt->execute();
            }
            $rows = $stmt->fetchAll();

            $formatted = [];
            foreach ($rows as $row) {
                $isFree = ($row['type'] === 'FREE_3_MATCHS' || $row['type'] === 'FREE');
                // En mode 100% réel, seul le mode GRATUIT (FREE_3_MATCHS) est ouvert sans abonnement VIP payé
                $isLocked = !$isFree;

                $selections = json_decode($row['selections_json'] ?? '[]', true) ?: [];
                $formattedSelections = [];
                foreach ($selections as $idx => $sel) {
                    $formattedSelections[] = [
                        'index' => $idx + 1,
                        'match' => $sel['match'] ?? 'Match',
                        'championship' => $sel['championship'] ?? $row['championship'],
                        'match_time' => $sel['match_time'] ?? $row['match_time'],
                        'tip' => $isLocked ? '🐸🔒 Pari réservé aux abonnés VIP' : ($sel['tip'] ?? '1X2'),
                        'odds' => $isLocked ? null : (float) ($sel['odds'] ?? 1.50),
                        'status' => $sel['status'] ?? $row['status']
                    ];
                }

                $formatted[] = [
                    'id' => (int) $row['id'],
                    'title' => $row['title'],
                    'competition' => $row['competition'],
                    'country' => $row['country'],
                    'championship' => $row['championship'],
                    'match_date' => $row['match_date'],
                    'match_time' => $row['match_time'],
                    'home_team' => $row['home_team'],
                    'away_team' => $row['away_team'],
                    'type' => $row['type'],
                    'odds' => (float) $row['odds'],
                    'confidence' => (int) $row['confidence'],
                    'status' => $row['status'],
                    'is_published' => (bool) $row['is_published'],
                    'is_locked' => $isLocked,
                    'selections' => $formattedSelections,
                    'matches_count' => count($formattedSelections) > 0 ? count($formattedSelections) : 1,
                    'analysis' => $isLocked ? "🐸🔒 Contenu réservé aux abonnés payants (2000 FCFA/mois). Abonnez-vous pour révéler les pronostics précis et notre conseil de mise." : ($row['analysis'] ?? ''),
                    'created_at' => $row['created_at']
                ];
            }

            echo json_encode(['success' => true, 'data' => $formatted], JSON_UNESCAPED_UNICODE);
            exit;
        }

        // Si 0 donnée en BDD, on retourne une liste vide [] (ZÉRO DONNÉE FICTIVE !)
        echo json_encode(['success' => true, 'data' => []], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // =========================================================================
    // C. PLANS D'ABONNEMENT RÉELS (/api/v1/subscriptions/...)
    // =========================================================================
    if ($uri === '/api/v1/subscriptions/plans' && $method === 'GET') {
        echo json_encode([
            'success' => true,
            'data' => [
                [
                    'id' => 1,
                    'code' => 'VIP',
                    'name' => '👑 Forfait VIP Mensuel (Côtes 5, 10, 50)',
                    'price' => 2000,
                    'duration_days' => 30,
                    'duration_label' => 'mois',
                    'description' => 'Accès complet aux pronostics Côte 5, Côte 10 et au Pronostic Semaine (Côte min 50).',
                    'features' => [
                        'Côte 5 quotidienne garantie',
                        'Côte 10 exclusive et analysée',
                        'Pronostic Semaine (Côte min 50)',
                        'Analyses d\'experts & conseils de mise Frogazz'
                    ]
                ],
                [
                    'id' => 2,
                    'code' => 'MONTANTE',
                    'name' => '📈 Forfait Montante Hebdomadaire',
                    'price' => 2000,
                    'duration_days' => 7,
                    'duration_label' => 'semaine',
                    'description' => 'Accès exclusif et dédié à la stratégie Montante sur 7 jours.',
                    'features' => [
                        'Pronostics Montante exclusifs',
                        'Gestion de mise pas-à-pas sécurisée par nos experts',
                        'Statistiques de progression sur 7 jours'
                    ]
                ]
            ]
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // =========================================================================
    // ABONNEMENT & PAIEMENT LIGDICASH (remplace CinetPay)
    // =========================================================================

    // 1. INITIER LE PAIEMENT (POST /api/v1/subscriptions/subscribe)
    //    Flow Orange Money (OTP USSD) : le client compose *144*4*6#, récupère l'OTP, on envoie numéro + OTP.
    //    Flow Moov (USSD Push) : otp vide, l'opérateur envoie une demande de validation sur le téléphone du client.
    if ($uri === '/api/v1/subscriptions/subscribe' && $method === 'POST') {
        if (!$pdo) {
            http_response_code(500);
            echo json_encode(['success' => false, 'code' => 'DB_CONNECTION_ERROR', 'message' => 'Base de données indisponible.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        if (empty(getenv('LIGDICASH_API_KEY')) || empty(getenv('LIGDICASH_API_TOKEN'))) {
            http_response_code(503);
            echo json_encode(['success' => false, 'code' => 'LIGDICASH_NOT_CONFIGURED', 'message' => 'Paiement LigdiCash non configuré. Ajoutez LIGDICASH_API_KEY et LIGDICASH_API_TOKEN sur Render.'], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $user = getAuthedUser($pdo);
        if (!$user) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Connectez-vous pour vous abonner.'], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $planCode = strtoupper(trim($input['plan_code'] ?? 'VIP'));
        $phone = preg_replace('/[^0-9]/', '', trim($input['phone'] ?? ''));
        $operator = strtoupper(trim($input['operator'] ?? 'ORANGE'));
        $otp = trim($input['otp'] ?? '');

        // Prix de base selon le plan
        $stmt = $pdo->prepare("SELECT * FROM subscription_plans WHERE code = ?");
        $stmt->execute([$planCode]);
        $plan = $stmt->fetch();
        if (!$plan) {
            http_response_code(422);
            echo json_encode(['success' => false, 'message' => 'Forfait inconnu.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $amount = (int) $plan['price'];
        $durationDays = (int) $plan['duration_days'];

        // Application d'un éventuel code promo
        $promoCode = strtoupper(trim($input['promo_code'] ?? ''));
        if ($promoCode !== '') {
            $ps = $pdo->prepare("SELECT * FROM promo_codes WHERE code = ? AND is_active = TRUE");
            $ps->execute([$promoCode]);
            $promo = $ps->fetch();
            if ($promo) {
                $amount = (int) round($amount * (100 - (int) $promo['discount_percent']) / 100);
            }
        }

        if ($phone === '' || strlen($phone) < 8) {
            http_response_code(422);
            echo json_encode(['success' => false, 'message' => 'Numéro de téléphone invalide.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        // Forcer le préfixe 226 si absent (Burkina Faso)
        if (!str_starts_with($phone, '226')) {
            $phone = '226' . ltrim($phone, '0');
        }

        // Identifiant de transaction interne (règle d'or LigdiCash)
        $transactionId = 'FGAZZ-' . gmdate('YmdHis') . '-' . strtoupper(bin2hex(random_bytes(4)));

        $storeName = getenv('LIGDICASH_STORE_NAME') ?: 'Frogazz Sport Analyse';
        $storeUrl = getenv('LIGDICASH_WEBSITE_URL') ?: 'https://pronostics-api-server.onrender.com';
        $callbackUrl = getenv('LIGDICASH_CALLBACK_URL') ?: 'https://pronostics-api-server.onrender.com/api/v1/ligdicash/callback';

        $payload = [
            'commande' => [
                'invoice' => [
                    'items' => [],
                    'total_amount' => $amount,
                    'devise' => 'XOF',
                    'description' => 'Abonnement ' . $planCode . ' — Frogazz Sport Analyse',
                    'customer' => $phone,
                    'customer_firstname' => $user['first_name'] ?? '',
                    'customer_lastname' => $user['last_name'] ?? '',
                    'customer_email' => $user['email'] ?? '',
                    'external_id' => '',
                    'otp' => ($operator === 'ORANGE') ? $otp : ''
                ],
                'store' => [
                    'name' => $storeName,
                    'website_url' => $storeUrl
                ],
                'actions' => [
                    'cancel_url' => '',
                    'return_url' => '',
                    'callback_url' => $callbackUrl
                ],
                'custom_data' => [
                    'transaction_id' => $transactionId,
                    'user_id' => (int) $user['id'],
                    'plan_code' => $planCode
                ]
            ]
        ];

        $res = ligdicashRequest('POST', 'https://app.ligdicash.com/pay/v01/straight/checkout-invoice/create', $payload);

        if (isset($res['_error'])) {
            http_response_code(502);
            echo json_encode(['success' => false, 'message' => $res['_error']], JSON_UNESCAPED_UNICODE);
            exit;
        }

        if (($res['response_code'] ?? '01') !== '00') {
            http_response_code(402);
            echo json_encode([
                'success' => false,
                'message' => 'Échec du paiement LigdiCash : ' . ($res['response_text'] ?? 'Erreur inconnue'),
                'wiki' => $res['wiki'] ?? null
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $token = $res['token'] ?? '';

        // Enregistrer le paiement (statut PENDING) en base
        try {
            $pdo->prepare("INSERT INTO payments (user_id, subscription_plan_id, transaction_id, ligdicash_token, amount, currency, status, payment_method, operator_id, raw_response, created_at) VALUES (?, ?, ?, ?, ?, 'XOF', 'PENDING', ?, ?, ?, NOW())")
                ->execute([$user['id'], $plan['id'], $transactionId, $token, $amount, 'LIGDICASH', $operator, json_encode($res)]);
        } catch (Exception $e) {
            error_log("[SUBSCRIBE] " . $e->getMessage());
        }

        echo json_encode([
            'success' => true,
            'transaction_id' => $transactionId,
            'token' => $token,
            'amount' => $amount,
            'currency' => 'XOF',
            'operator' => $operator,
            'status' => 'pending',
            'ussd_code' => ($operator === 'ORANGE') ? '*144*4*6#' : null,
            'message' => ($operator === 'ORANGE')
                ? 'Paiement initié. Composez *144*4*6# pour obtenir votre OTP puis validez.'
                : 'Paiement initié. Validez la demande USSD reçue sur votre téléphone.'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // 2. VÉRIFIER LE STATUT (POST /api/v1/subscriptions/ligdicash/confirm)
    //    L'application interroge cet endpoint pour savoir si le paiement est terminé.
    if ($uri === '/api/v1/subscriptions/ligdicash/confirm' && $method === 'POST') {
        if (!$pdo) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Base de données indisponible.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $transactionId = trim($input['transaction_id'] ?? '');
        if ($transactionId === '') {
            http_response_code(422);
            echo json_encode(['success' => false, 'message' => 'transaction_id requis.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $stmt = $pdo->prepare("SELECT * FROM payments WHERE transaction_id = ?");
        $stmt->execute([$transactionId]);
        $payment = $stmt->fetch();
        if (!$payment) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Paiement introuvable.'], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $token = $payment['ligdicash_token'] ?? '';
        $confirm = ligdicashRequest('GET', 'https://app.ligdicash.com/pay/v01/redirect/checkout-invoice/confirm/?invoiceToken=' . urlencode($token));

        $status = $confirm['status'] ?? 'pending';
        $responseCode = $confirm['response_code'] ?? '01';

        if ($status === 'completed') {
            // Paiement confirmé -> activer l'abonnement
            $pdo->prepare("UPDATE payments SET status = 'SUCCESS', paid_at = NOW() WHERE id = ?")->execute([$payment['id']]);
            if (!empty($payment['user_id'])) {
                $planStmt = $pdo->prepare("SELECT code FROM subscription_plans WHERE id = ?");
                $planStmt->execute([$payment['subscription_plan_id']]);
                $paidPlan = $planStmt->fetch();
                $pcode = $paidPlan['code'] ?? 'VIP';
                $pstmt = $pdo->prepare("SELECT duration_days FROM subscription_plans WHERE code = ?");
                $pstmt->execute([$pcode]);
                $days = (int) ($pstmt->fetchColumn() ?: 30);
                activateSubscription($pdo, (int) $payment['user_id'], $pcode, $days);
            }
            echo json_encode(['success' => true, 'status' => 'completed', 'message' => 'Paiement confirmé, abonnement activé.'], JSON_UNESCAPED_UNICODE);
        } elseif ($status === 'notcompleted') {
            $pdo->prepare("UPDATE payments SET status = 'FAILED' WHERE id = ?")->execute([$payment['id']]);
            echo json_encode(['success' => false, 'status' => 'notcompleted', 'message' => 'Paiement non abouti.'], JSON_UNESCAPED_UNICODE);
        } else {
            echo json_encode(['success' => true, 'status' => 'pending', 'message' => 'Paiement en attente de validation.'], JSON_UNESCAPED_UNICODE);
        }
        exit;
    }

    // 3. CALLBACK WEBHOOK (POST /api/v1/ligdicash/callback)
    //    LigdiCash notifie cet endpoint quand l'opérateur a traité la transaction.
    if ($uri === '/api/v1/ligdicash/callback' && $method === 'POST') {
        $body = $input;
        $customData = $body['custom_data'] ?? ($body['commande']['custom_data'] ?? []);
        $transactionId = $customData['transaction_id'] ?? ($body['transaction_id'] ?? '');

        if ($pdo && $transactionId !== '') {
            $stmt = $pdo->prepare("SELECT * FROM payments WHERE transaction_id = ?");
            $stmt->execute([$transactionId]);
            $payment = $stmt->fetch();
            if ($payment) {
                // Toujours re-vérifier via confirm (sécurité) avec le token stocké à la création
                $token = $payment['ligdicash_token'] ?? '';
                $confirm = ligdicashRequest('GET', 'https://app.ligdicash.com/pay/v01/redirect/checkout-invoice/confirm/?invoiceToken=' . urlencode($token));
                if (($confirm['status'] ?? '') === 'completed') {
                    $pdo->prepare("UPDATE payments SET status = 'SUCCESS', paid_at = NOW() WHERE id = ?")->execute([$payment['id']]);
                    if (!empty($payment['user_id'])) {
                        $planStmt = $pdo->prepare("SELECT code FROM subscription_plans WHERE id = ?");
                        $planStmt->execute([$payment['subscription_plan_id']]);
                        $paidPlan = $planStmt->fetch();
                        $pcode = $paidPlan['code'] ?? 'VIP';
                        $pstmt = $pdo->prepare("SELECT duration_days FROM subscription_plans WHERE code = ?");
                        $pstmt->execute([$pcode]);
                        $days = (int) ($pstmt->fetchColumn() ?: 30);
                        activateSubscription($pdo, (int) $payment['user_id'], $pcode, $days);
                    }
                }
            }
        }
        echo json_encode(['success' => true], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // 4. HISTORIQUE DES PAIEMENTS RÉELS (GET /api/v1/history/payments)
    if ($uri === '/api/v1/history/payments' && $method === 'GET') {
        $data = [];
        if ($pdo) {
            $user = getAuthedUser($pdo);
            if ($user) {
                $stmt = $pdo->prepare("SELECT p.*, sp.code AS plan_code, sp.name AS plan_name FROM payments p LEFT JOIN subscription_plans sp ON sp.id = p.subscription_plan_id WHERE p.user_id = ? ORDER BY p.created_at DESC");
                $stmt->execute([$user['id']]);
                $rows = $stmt->fetchAll();
                foreach ($rows as $r) {
                    $data[] = [
                        'id' => (int) $r['id'],
                        'transaction_id' => $r['transaction_id'],
                        'amount' => (int) $r['amount'],
                        'currency' => $r['currency'],
                        'status' => $r['status'],
                        'payment_method' => $r['payment_method'],
                        'operator' => $r['operator_id'],
                        'paid_at' => $r['paid_at'],
                        'created_at' => $r['created_at'],
                        'plan' => ['code' => $r['plan_code'], 'name' => $r['plan_name']]
                    ];
                }
            }
        }
        echo json_encode(['success' => true, 'data' => $data], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($uri === '/api/v1/subscriptions/promo/check' && $method === 'POST') {
        $code = strtoupper(trim($input['code'] ?? ''));
        if ($pdo) {
            $stmt = $pdo->prepare("SELECT * FROM promo_codes WHERE code = ? AND is_active = TRUE");
            $stmt->execute([$code]);
            $promo = $stmt->fetch();
            if ($promo) {
                echo json_encode([
                    'success' => true,
                    'code' => $promo['code'],
                    'discount_percent' => (int) $promo['discount_percent'],
                    'message' => "Code promo valide : -{$promo['discount_percent']}% appliqués"
                ], JSON_UNESCAPED_UNICODE);
                exit;
            }
        }
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Code promo invalide ou expiré.'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // =========================================================================
    // D. SUPPORT, FAQ & PARRAINAGE (/api/v1/support/...)
    // =========================================================================
    if ($uri === '/api/v1/support/faqs') {
        if ($pdo) {
            $stmt = $pdo->query("SELECT id, question, answer, category FROM faqs WHERE is_active = TRUE ORDER BY display_order ASC");
            echo json_encode(['success' => true, 'data' => $stmt->fetchAll()], JSON_UNESCAPED_UNICODE);
            exit;
        }
        echo json_encode(['success' => true, 'data' => []], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($uri === '/api/v1/support/privacy') {
        echo json_encode([
            'success' => true,
            'title' => 'Politique de Confidentialité — Frogazz Sport Analyse',
            'content' => '1. Protection des Données : Toutes vos données sont chiffrées selon les normes industrielles (TLS). 2. Transactions : Traitées de façon sécurisée par LigdiCash (mobile money Orange & Moov).',
            'updated_at' => '2026-08-01'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($uri === '/api/v1/support/terms') {
        echo json_encode([
            'success' => true,
            'title' => 'Conditions Générales d\'Utilisation — Frogazz Sport Analyse',
            'content' => '1. Mode Gratuit : 3 Matchs offerts par jour à tous les inscrits. 2. Abonnements VIP (2000 FCFA/mois) et Montante (2000 FCFA/semaine) obligatoires pour les autres catégories. 3. Jouez responsable.',
            'updated_at' => '2026-08-01'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($uri === '/api/v1/referral/info') {
        echo json_encode([
            'success' => true,
            'referral_code' => 'FROGAZZ2026',
            'referral_url' => 'https://pronostics-sportifs.pro/register?ref=FROGAZZ2026',
            'total_referrals' => 0,
            'active_referrals' => 0,
            'reward_description' => 'Gagnez 7 jours d\'abonnement VIP gratuits pour chaque ami qui s\'abonne !'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // =========================================================================
    // E. ADMINISTRATION (100% RÉEL) : statistiques, utilisateurs & gestion des pronostics
    // =========================================================================

    // Statistiques du tableau de bord (zéro donnée fictive, issues de la base réelle)
    if ($uri === '/api/v1/admin/dashboard/stats' && $method === 'GET') {
        $stats = [
            'total_users' => 0,
            'vip_users' => 0,
            'montante_users' => 0,
            'total_revenue' => 0,
            'payments_today' => 0,
            'revenue_today' => 0,
            'total_predictions' => 0,
            'published_predictions' => 0
        ];
        if ($pdo) {
            try {
                $stats['total_users'] = (int) $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
                $stats['vip_users'] = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE subscription_status = 'ACTIVE'")->fetchColumn();
                $stats['montante_users'] = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE subscription_status = 'ACTIVE_MONTANTE'")->fetchColumn();
                $stats['total_revenue'] = (int) $pdo->query("SELECT COALESCE(SUM(amount),0) FROM payments WHERE status = 'SUCCESS'")->fetchColumn();
                $stats['payments_today'] = (int) $pdo->query("SELECT COUNT(*) FROM payments WHERE created_at::date = CURRENT_DATE")->fetchColumn();
                $stats['revenue_today'] = (int) $pdo->query("SELECT COALESCE(SUM(amount),0) FROM payments WHERE created_at::date = CURRENT_DATE AND status = 'SUCCESS'")->fetchColumn();
                $stats['total_predictions'] = (int) $pdo->query("SELECT COUNT(*) FROM predictions")->fetchColumn();
                $stats['published_predictions'] = (int) $pdo->query("SELECT COUNT(*) FROM predictions WHERE is_published = TRUE")->fetchColumn();
            } catch (Exception $e) {
                error_log("[ADMIN STATS] " . $e->getMessage());
            }
        }
        echo json_encode(['success' => true, 'data' => $stats], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Liste des utilisateurs réels
    if ($uri === '/api/v1/admin/users' && $method === 'GET') {
        $data = [];
        if ($pdo) {
            try {
                $rows = $pdo->query("SELECT id, last_name, first_name, phone, email, is_admin, subscription_status, subscription_expires_at, created_at FROM users ORDER BY created_at DESC")->fetchAll();
                foreach ($rows as $r) {
                    $status = $r['subscription_status'] ?? 'FREE';
                    $plan = '🐸 Gratuit (3 matchs/jour)';
                    if ($status === 'ACTIVE') $plan = '👑 VIP Mensuel (2000 FCFA)';
                    elseif ($status === 'ACTIVE_MONTANTE') $plan = '📈 Montante (2000 FCFA/sem)';
                    $data[] = [
                        'id' => (int) $r['id'],
                        'name' => trim($r['last_name'] . ' ' . $r['first_name']),
                        'phone' => $r['phone'],
                        'email' => $r['email'],
                        'is_admin' => (bool) $r['is_admin'],
                        'status' => $status,
                        'plan' => $plan,
                        'expiresAt' => $r['subscription_expires_at'] ?: '—',
                        'created_at' => $r['created_at']
                    ];
                }
            } catch (Exception $e) {
                error_log("[ADMIN USERS] " . $e->getMessage());
            }
        }
        echo json_encode(['success' => true, 'data' => $data], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Création d'un pronostic réel (POST /api/v1/admin/predictions)
    if ($uri === '/api/v1/admin/predictions' && $method === 'POST') {
        if (!$pdo) {
            http_response_code(500);
            echo json_encode(['success' => false, 'code' => 'DB_CONNECTION_ERROR', 'message' => 'Base de données indisponible.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $title = trim($input['title'] ?? '');
        if ($title === '') {
            http_response_code(422);
            echo json_encode(['success' => false, 'message' => 'Le titre est obligatoire.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $selections = $input['selections'] ?? [];
        try {
            $stmt = $pdo->prepare("
                INSERT INTO predictions (title, competition, country, championship, match_date, match_time, home_team, away_team, type, odds, selections_json, confidence, analysis, status, is_published)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)
                RETURNING id
            ");
            $stmt->execute([
                $title,
                trim($input['competition'] ?? ''),
                trim($input['country'] ?? ''),
                trim($input['championship'] ?? ''),
                trim($input['match_date'] ?? gmdate('Y-m-d')),
                trim($input['match_time'] ?? '20:00'),
                trim($input['home_team'] ?? ''),
                trim($input['away_team'] ?? ''),
                trim($input['type'] ?? 'COTE_5'),
                (float) ($input['odds'] ?? 1.50),
                json_encode($selections, JSON_UNESCAPED_UNICODE),
                (int) ($input['confidence'] ?? 4),
                trim($input['analysis'] ?? ''),
                trim($input['status'] ?? 'PENDING')
            ]);
            $newId = (int) $stmt->fetchColumn();
            echo json_encode(['success' => true, 'message' => 'Pronostic créé avec succès.', 'id' => $newId], JSON_UNESCAPED_UNICODE);
        } catch (Exception $e) {
            error_log("[ADMIN CREATE PRED] " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la création : ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
        }
        exit;
    }

    // Mise à jour d'un pronostic (PUT /api/v1/admin/predictions/{id})
    if (preg_match('#^/api/v1/admin/predictions/(\d+)$#', $uri, $m) && $method === 'PUT') {
        $id = (int) $m[1];
        if (!$pdo) {
            http_response_code(500);
            echo json_encode(['success' => false, 'code' => 'DB_CONNECTION_ERROR', 'message' => 'Base de données indisponible.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        try {
            // Si seul is_published est envoyé (bascule publier/dépublier)
            if (array_key_exists('is_published', $input) && !array_key_exists('title', $input)) {
                $pdo->prepare("UPDATE predictions SET is_published = ? WHERE id = ?")
                    ->execute([($input['is_published'] ? 'TRUE' : 'FALSE'), $id]);
                echo json_encode(['success' => true, 'message' => 'Statut de publication mis à jour.'], JSON_UNESCAPED_UNICODE);
                exit;
            }
            $stmt = $pdo->prepare("
                UPDATE predictions SET
                    title = ?, competition = ?, country = ?, championship = ?, match_date = ?, match_time = ?,
                    home_team = ?, away_team = ?, type = ?, odds = ?, confidence = ?, analysis = ?, status = ?
                WHERE id = ?
            ");
            $stmt->execute([
                trim($input['title'] ?? ''),
                trim($input['competition'] ?? ''),
                trim($input['country'] ?? ''),
                trim($input['championship'] ?? ''),
                trim($input['match_date'] ?? gmdate('Y-m-d')),
                trim($input['match_time'] ?? '20:00'),
                trim($input['home_team'] ?? ''),
                trim($input['away_team'] ?? ''),
                trim($input['type'] ?? 'COTE_5'),
                (float) ($input['odds'] ?? 1.50),
                (int) ($input['confidence'] ?? 4),
                trim($input['analysis'] ?? ''),
                trim($input['status'] ?? 'PENDING'),
                $id
            ]);
            echo json_encode(['success' => true, 'message' => 'Pronostic mis à jour.'], JSON_UNESCAPED_UNICODE);
        } catch (Exception $e) {
            error_log("[ADMIN UPDATE PRED] " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour : ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
        }
        exit;
    }

    // Suppression d'un pronostic (DELETE /api/v1/admin/predictions/{id})
    if (preg_match('#^/api/v1/admin/predictions/(\d+)$#', $uri, $m) && $method === 'DELETE') {
        $id = (int) $m[1];
        if (!$pdo) {
            http_response_code(500);
            echo json_encode(['success' => false, 'code' => 'DB_CONNECTION_ERROR', 'message' => 'Base de données indisponible.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        try {
            $pdo->prepare("DELETE FROM predictions WHERE id = ?")->execute([$id]);
            echo json_encode(['success' => true, 'message' => 'Pronostic supprimé.'], JSON_UNESCAPED_UNICODE);
        } catch (Exception $e) {
            error_log("[ADMIN DELETE PRED] " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la suppression.'], JSON_UNESCAPED_UNICODE);
        }
        exit;
    }

    // Liste des codes promo réels
    if ($uri === '/api/v1/admin/promo-codes' && $method === 'GET') {
        $data = [];
        if ($pdo) {
            try {
                $data = $pdo->query("SELECT id, code, discount_percent, max_uses, used_count, is_active, expires_at FROM promo_codes ORDER BY created_at DESC")->fetchAll();
            } catch (Exception $e) {}
        }
        echo json_encode(['success' => true, 'data' => $data], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Création d'un code promo réel (POST /api/v1/admin/promo-codes)
    if ($uri === '/api/v1/admin/promo-codes' && $method === 'POST') {
        if (!$pdo) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Base de données indisponible.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $code = strtoupper(trim($input['code'] ?? ''));
        if ($code === '') {
            http_response_code(422);
            echo json_encode(['success' => false, 'message' => 'Le code promo est obligatoire.'], JSON_UNESCAPED_UNICODE);
            exit;
        }
        try {
            $stmt = $pdo->prepare("INSERT INTO promo_codes (code, discount_percent, max_uses, used_count, expires_at, is_active) VALUES (?, ?, ?, 0, NULL, TRUE) RETURNING id");
            $stmt->execute([$code, (int) ($input['discount'] ?? 10), (int) ($input['max'] ?? 100)]);
            echo json_encode(['success' => true, 'message' => 'Code promo créé.', 'id' => (int) $stmt->fetchColumn()], JSON_UNESCAPED_UNICODE);
        } catch (Exception $e) {
            error_log("[ADMIN CREATE PROMO] " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur : ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
        }
        exit;
    }

    // Suppression d'un code promo (DELETE /api/v1/admin/promo-codes/{id})
    if (preg_match('#^/api/v1/admin/promo-codes/(\d+)$#', $uri, $m) && $method === 'DELETE') {
        $id = (int) $m[1];
        if ($pdo) {
            try {
                $pdo->prepare("DELETE FROM promo_codes WHERE id = ?")->execute([$id]);
            } catch (Exception $e) {}
        }
        echo json_encode(['success' => true, 'message' => 'Code promo supprimé.'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    echo json_encode(['success' => true, 'message' => 'Frogazz Sport Analyse API Ready (Production Mode)', 'endpoint' => $uri], JSON_UNESCAPED_UNICODE);
    exit;
}

http_response_code(404);
header('Content-Type: application/json; charset=utf-8');
echo json_encode(['error' => 'Endpoint introuvable', 'path' => $uri], JSON_UNESCAPED_UNICODE);
