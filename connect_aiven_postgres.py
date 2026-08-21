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

    print("🌱 Initialisation des données de production réelles (Forfaits VIP/Montante, Admin, FAQs)...")

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

    # 2. Utilisateur Administrateur unique pour la production (mot de passe réel haché bcrypt)
    #    Identifiants admin : admin@frogazz.pro  /  Frogazz@Admin2026  (À CHANGER après la première connexion)
    cur.execute("""
        INSERT INTO users (last_name, first_name, phone, email, password, is_admin, subscription_status, free_trial_expires_at, referral_code)
        VALUES
        ('Admin', 'Frogazz', '+22600000000', 'admin@frogazz.pro', '$2b$12$PTCEdN0x/xSkN8Qo28NvVOBbIAIvSN2VeHiCnEkJuAYd7AMAzzClK', TRUE, 'FREE', NULL, 'ADMINVIP')
        RETURNING id, email;
    """)

    # 3. MODE 100% RÉEL : AUCUN pronostic, code promo ou utilisateur fictif inséré.
    #    Les pronostics réels seront publiés par l'administrateur via le panneau /admin.
    print("✅ Schéma réel créé avec succès — ZÉRO donnée fictive (0 pronostic, 0 code promo fictif, 0 utilisateur fictif).")

    # 4. FAQs réelles (sans mention d'essai 48h — suppression de l'offre fictive)
    cur.execute("""
        INSERT INTO faqs (question, answer, category, display_order)
        VALUES
        ('Comment fonctionne le mode gratuit ?', 'Dès votre inscription, vous accédez gratuitement au Combiné Gratuit de 3 matchs publié chaque jour. Les catégories Côte 5, Côte 10, Côte 50 et Montante nécessitent un abonnement payant.', 'ABONNEMENT', 1),
        ('Quelle est la différence entre VIP et Montante ?', 'VIP (2000 FCFA/mois) donne accès aux Côtes 5, 10 et 50. Montante (2000 FCFA/semaine) est réservé à la stratégie Montante.', 'ABONNEMENT', 2),
        ('Comment payer par Orange Money ou Wave avec PayDunya ?', 'Sélectionnez votre forfait, choisissez Mobile Money ou Wave, saisissez votre numéro et validez sur votre mobile !', 'PAIEMENT', 3);
    """)

    print("✅ Base de données réelle initialisée : schéma + forfaits + admin + FAQs réelles (zéro donnée fictive).")

    cur.close()
    conn.close()
    print("🎉 TERMINÉ ! Votre base de données Aiven PostgreSQL est 100% opérationnelle !")

if __name__ == '__main__':
    main()
