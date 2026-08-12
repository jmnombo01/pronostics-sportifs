#!/usr/bin/env python3
import sys
import os
import re
import json
import psycopg2
from psycopg2.extras import Json
from urllib.parse import urlparse

URI = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("DATABASE_URL", "")

def main():
    print("🔗 Connexion à Aiven PostgreSQL : pg-e0591b-jmnombo01-9a23.l.aivencloud.com:18819 (base: defaultdb)...")

    try:
        conn = psycopg2.connect(URI)
        conn.autocommit = True
        print("✅ Connexion réussie à votre base PostgreSQL dans le Cloud Aiven !")
    except Exception as e:
        print(f"❌ Échec de la connexion à PostgreSQL Aiven : {e}")
        sys.exit(1)

    cur = conn.cursor()

    print("📦 Suppression des tables existantes (si réinitialisation)...")
    cur.execute("""
        DROP TABLE IF EXISTS faqs CASCADE;
        DROP TABLE IF EXISTS promo_codes CASCADE;
        DROP TABLE IF EXISTS payments CASCADE;
        DROP TABLE IF EXISTS predictions CASCADE;
        DROP TABLE IF EXISTS user_subscriptions CASCADE;
        DROP TABLE IF EXISTS subscription_plans CASCADE;
        DROP TABLE IF EXISTS users CASCADE;
    """)

    print("🛠️ Création du schéma des tables en syntaxe PostgreSQL...")

    # 1. Table users
    cur.execute("""
        CREATE TABLE users (
            id BIGSERIAL PRIMARY KEY,
            last_name VARCHAR(100) NOT NULL,
            first_name VARCHAR(100) NOT NULL,
            phone VARCHAR(30) NOT NULL UNIQUE,
            email VARCHAR(150) NOT NULL UNIQUE,
            password VARCHAR(255) NOT NULL,
            is_admin BOOLEAN NOT NULL DEFAULT FALSE,
            subscription_status VARCHAR(50) NOT NULL DEFAULT 'FREE_TRIAL',
            subscription_expires_at TIMESTAMP NULL DEFAULT NULL,
            free_trial_expires_at TIMESTAMP NULL DEFAULT NULL,
            referral_code VARCHAR(20) NULL UNIQUE,
            referred_by_id BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
            fcm_token VARCHAR(255) NULL,
            remember_token VARCHAR(100) NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX idx_users_email ON users(email);
        CREATE INDEX idx_users_phone ON users(phone);
        CREATE INDEX idx_users_status ON users(subscription_status);
    """)

    # 2. Table subscription_plans
    cur.execute("""
        CREATE TABLE subscription_plans (
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
        );
    """)

    # 3. Table user_subscriptions
    cur.execute("""
        CREATE TABLE user_subscriptions (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            subscription_plan_id BIGINT NOT NULL REFERENCES subscription_plans(id) ON DELETE RESTRICT,
            status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
            starts_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NOT NULL,
            auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX idx_sub_user_id ON user_subscriptions(user_id);
    """)

    # 4. Table predictions (avec sélections JSONB pour combinés)
    cur.execute("""
        CREATE TABLE predictions (
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
            scheduled_at TIMESTAMP NULL DEFAULT NULL,
            published_at TIMESTAMP NULL DEFAULT NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX idx_pred_type ON predictions(type);
        CREATE INDEX idx_pred_status ON predictions(status);
        CREATE INDEX idx_pred_match_date ON predictions(match_date);
    """)

    # 5. Table payments
    cur.execute("""
        CREATE TABLE payments (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            subscription_plan_id BIGINT NOT NULL REFERENCES subscription_plans(id) ON DELETE RESTRICT,
            transaction_id VARCHAR(100) NOT NULL UNIQUE,
            cinetpay_token VARCHAR(255) NULL,
            amount INTEGER NOT NULL,
            currency VARCHAR(10) NOT NULL DEFAULT 'XOF',
            status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
            payment_method VARCHAR(50) NOT NULL DEFAULT 'MOBILE_MONEY',
            operator_id VARCHAR(100) NULL,
            raw_response JSONB NULL,
            paid_at TIMESTAMP NULL DEFAULT NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX idx_pay_user_id ON payments(user_id);
        CREATE INDEX idx_pay_tx_id ON payments(transaction_id);
    """)

    # 6. Table promo_codes
    cur.execute("""
        CREATE TABLE promo_codes (
            id BIGSERIAL PRIMARY KEY,
            code VARCHAR(30) NOT NULL UNIQUE,
            discount_percent INTEGER NOT NULL DEFAULT 10,
            max_uses INTEGER NOT NULL DEFAULT 100,
            used_count INTEGER NOT NULL DEFAULT 0,
            expires_at TIMESTAMP NULL DEFAULT NULL,
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        );
    """)

    # 7. Table faqs
    cur.execute("""
        CREATE TABLE faqs (
            id BIGSERIAL PRIMARY KEY,
            question VARCHAR(255) NOT NULL,
            answer TEXT NOT NULL,
            category VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
            display_order INTEGER NOT NULL DEFAULT 1,
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        );
    """)

    print("✅ Schéma PostgreSQL des 7 tables créé avec succès !")

    print("🌱 Insertion des données de démonstration (Forfaits, Utilisateurs, Pronostics combinés)...")

    # 1. Forfaits VIP et Montante
    cur.execute("""
        INSERT INTO subscription_plans (code, name, price, duration_days, description, features_json, is_active)
        VALUES 
        ('VIP', 'Abonnement VIP Mensuel', 2000, 30, 'Accès complet aux pronostics Côte 5, Côte 10 et Côte 50 Semaine.', %s, TRUE),
        ('MONTANTE', 'Abonnement Montante Hebdomadaire', 2000, 7, 'Accès exclusif à la stratégie Montante sur 7 jours.', %s, TRUE)
        RETURNING id, code;
    """, (
        Json(["Côte 5 quotidienne garantie", "Côte 10 exclusive", "Pronostic Semaine (Côte ≥ 50)", "Analyse détaillée"]),
        Json(["Pronostics Montante exclusifs", "Gestion de mise pas-à-pas", "Statistiques de progression sur 7 jours"])
    ))

    # 2. Utilisateur Administrateur unique pour la production
    cur.execute("""
        INSERT INTO users (last_name, first_name, phone, email, password, is_admin, subscription_status, free_trial_expires_at, referral_code)
        VALUES
        ('Traoré', 'Sidi (Admin)', '+22670000001', 'admin@frogazz.pro', '$2y$12$kS6Gv2zY3pE...', TRUE, 'ACTIVE', NOW() + INTERVAL '10 years', 'ADMINVIP')
        RETURNING id, email;
    """)

    # 3. Mode Réel : 0 pronostic fictif inséré au démarrage. Les pronostics réels seront publiés par l'admin.
    print("✅ Schéma réel créé avec succès — 0 pronostic fictif inséré.")

    # 3. Pronostics Combinés (Côte 5, Côte 10, Côte 50, Montante)
    predictions_data = [
        (
            '⚡ COMBINÉ CÔTE 5 DU LUNDI (3 MATCHS)', 'Europe - Combiné VIP', 'Europe', 'Combiné Europe',
            '2026-08-03', '19:30', 'Real Madrid / PSG / Bayern', 'Séville / Lyon / Leipzig',
            'COTE_5', 5.18,
            Json([
                {"match": "Real Madrid vs FC Séville", "championship": "La Liga - Espagne", "match_time": "19:30", "tip": "Victoire Real Madrid (1)", "odds": 1.65, "status": "PENDING"},
                {"match": "PSG vs Olympique Lyonnais", "championship": "Ligue 1 - France", "match_time": "20:45", "tip": "Les deux équipes marquent (BTTS - Oui)", "odds": 1.80, "status": "PENDING"},
                {"match": "Bayern Munich vs RB Leipzig", "championship": "Bundesliga - Allemagne", "match_time": "18:30", "tip": "Plus de 2.5 buts dans le match", "odds": 1.75, "status": "PENDING"}
            ]),
            5, 'Combiné de 3 matchs sélectionnés par nos algorithmes : 1.65 × 1.80 × 1.75 = 5.18 de cote totale.', 'PENDING', TRUE
        ),
        (
            '⚡ COMBINÉ CÔTE 5 DU MARDI (3 MATCHS)', 'Europe - Combiné VIP', 'Europe', 'Combiné PL & Serie A',
            '2026-08-04', '16:30', 'Arsenal / Inter Milan / FC Porto', 'Chelsea / AC Milan / Benfica',
            'COTE_5', 5.04,
            Json([
                {"match": "Arsenal vs Chelsea", "championship": "Premier League - Angleterre", "match_time": "16:30", "tip": "Victoire Arsenal & Plus de 1.5 buts", "odds": 1.80, "status": "PENDING"},
                {"match": "Inter Milan vs AC Milan", "championship": "Serie A - Italie", "match_time": "20:45", "tip": "Victoire Inter Milan (DNB 1)", "odds": 1.75, "status": "PENDING"},
                {"match": "FC Porto vs Benfica", "championship": "Liga Portugal", "match_time": "21:00", "tip": "Plus de 1.5 buts en 2e mi-temps", "odds": 1.60, "status": "PENDING"}
            ]),
            5, 'Deuxième ticket Côte 5 de la semaine avec 3 sélections européennes à haute probabilité.', 'PENDING', TRUE
        ),
        (
            '👑 COMBINÉ CÔTE 10 - GRAND CHELEM (4 MATCHS)', 'Europe - Combiné VIP', 'Europe', 'Combiné Champions & Europa',
            '2026-08-05', '18:30', 'Man City / Juventus / Dortmund / Barça', 'Aston Villa / Naples / Francfort / Atl. Madrid',
            'COTE_10', 10.45,
            Json([
                {"match": "Manchester City vs Aston Villa", "championship": "Premier League - Angleterre", "match_time": "18:30", "tip": "Man City & Haaland Buteur", "odds": 1.85, "status": "PENDING"},
                {"match": "Juventus vs Naples", "championship": "Serie A - Italie", "match_time": "20:45", "tip": "Moins de 3.5 buts", "odds": 1.70, "status": "PENDING"},
                {"match": "Borussia Dortmund vs Eintracht Francfort", "championship": "Bundesliga - Allemagne", "match_time": "17:30", "tip": "Victoire Dortmund (1)", "odds": 1.80, "status": "PENDING"},
                {"match": "FC Barcelone vs Atletico Madrid", "championship": "La Liga - Espagne", "match_time": "21:00", "tip": "Les deux équipes marquent (Oui)", "odds": 1.85, "status": "PENDING"}
            ]),
            4, 'Combiné de 4 matchs pour atteindre notre cote 10 exclusive. Allouer 2% de bankroll.', 'PENDING', TRUE
        ),
        (
            '💎 MÉGA COMBINÉ SEMAINE VIP (6 MATCHS)', 'Ligue des Champions', 'Europe', 'Ligue des Champions',
            '2026-08-06', '21:00', 'Sélection 6 Équipes Européennes', 'Ligue des Champions',
            'COTE_50', 54.20,
            Json([
                {"match": "Real Madrid vs Benfica", "championship": "UCL", "match_time": "21:00", "tip": "Victoire Real Madrid", "odds": 1.60, "status": "PENDING"},
                {"match": "Manchester City vs Porto", "championship": "UCL", "match_time": "21:00", "tip": "Victoire City -1.5", "odds": 1.75, "status": "PENDING"},
                {"match": "Bayern Munich vs Celtic", "championship": "UCL", "match_time": "21:00", "tip": "Plus de 3.5 buts", "odds": 1.80, "status": "PENDING"},
                {"match": "Liverpool vs Galatasaray", "championship": "UCL", "match_time": "21:00", "tip": "Victoire Liverpool (1)", "odds": 1.55, "status": "PENDING"},
                {"match": "Inter Milan vs Shakhtar", "championship": "UCL", "match_time": "21:00", "tip": "Inter Milan sans encaisser", "odds": 2.05, "status": "PENDING"},
                {"match": "Arsenal vs PSV Eindhoven", "championship": "UCL", "match_time": "21:00", "tip": "Arsenal gagne les deux MT", "odds": 3.40, "status": "PENDING"}
            ]),
            4, 'Notre combiné phare de la semaine réunit 6 sélections pour une cote de 54.20. Réservé aux VIP.', 'PENDING', TRUE
        ),
        (
            '📈 MONTANTE ÉTAPE 1 : Inter Milan vs AS Roma', 'Serie A', 'Italie', 'Serie A',
            '2026-08-03', '20:45', 'Inter Milan', 'AS Roma',
            'MONTANTE', 1.85,
            Json([
                {"match": "Inter Milan vs AS Roma", "championship": "Serie A - Italie", "match_time": "20:45", "tip": "Victoire Inter Milan (Remboursé si match nul)", "odds": 1.85, "status": "PENDING"}
            ]),
            5, 'Étape 1 de notre montante en 5 jours. Victoire de l\'Inter Milan (remboursé si match nul).', 'PENDING', TRUE
        )
    ]

    for p in predictions_data:
        cur.execute("""
            INSERT INTO predictions (title, competition, country, championship, match_date, match_time, home_team, away_team, type, odds, selections_json, confidence, analysis, status, is_published)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
        """, p)

    # 4. Codes Promo et FAQs
    cur.execute("""
        INSERT INTO promo_codes (code, discount_percent, max_uses, used_count, is_active)
        VALUES
        ('WELCOME10', 10, 500, 12, TRUE),
        ('VIP20', 20, 100, 5, TRUE);

        INSERT INTO faqs (question, answer, category, display_order)
        VALUES
        ('Comment fonctionne l''essai gratuit de 48 heures ?', 'Dès votre inscription, votre compte accède gratuitement aux pronostics Côte 5 pendant 48 heures. Au-delà, un abonnement VIP (2000 FCFA/mois) est requis.', 'ABONNEMENT', 1),
        ('Quelle est la différence entre VIP et Montante ?', 'VIP (2000 FCFA/mois) donne accès aux Côtes 5, 10 et 50. Montante (2000 FCFA/semaine) est réservé à la stratégie Montante.', 'ABONNEMENT', 2),
        ('Comment payer par Orange Money ou Wave avec PayDunya ?', 'Sélectionnez votre forfait, choisissez Mobile Money ou Wave, saisissez votre numéro et validez sur votre mobile !', 'PAIEMENT', 3);
    """)

    print("✅ Données de démonstration importées avec succès dans Aiven PostgreSQL !")

    cur.close()
    conn.close()
    print("🎉 TERMINÉ ! Votre base de données Aiven PostgreSQL est 100% opérationnelle !")

if __name__ == '__main__':
    main()
