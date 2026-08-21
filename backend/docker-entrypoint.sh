#!/usr/bin/env bash
set -e

# Utilise le port fourni par Render ($PORT), sinon 10000 par défaut
PORT=${PORT:-10000}

echo "👑 =================================================================="
echo "👑 DÉMARRAGE DU SERVEUR LARAVEL 12 SUR RENDER (PORT: $PORT)"
echo "👑 =================================================================="

# Assurer la création des dossiers de cache storage et bootstrap
mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
chmod -R 777 storage bootstrap/cache || true

# IMPORTANT : Le schéma de la base de données est géré par connect_aiven_postgres.py
# (tables : users, subscription_plans, predictions, payments, promo_codes, faqs...).
# On n'exécute PAS les migrations Laravel ici pour éviter d'écraser le schéma réel.

echo "🌐 Lancement du serveur Web HTTP Laravel sur 0.0.0.0:$PORT ..."
exec php -S 0.0.0.0:$PORT -t public public/index.php
