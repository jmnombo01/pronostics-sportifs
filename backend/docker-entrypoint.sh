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

# Si une base de données (PostgreSQL ou MySQL) est configurée dans Render, exécuter les migrations
if [ -n "$DB_HOST" ]; then
    echo "🐬 Connexion à la base $DB_CONNECTION ($DB_HOST)..."
    php artisan migrate --force || echo "⚠️ Attention : Migration en attente de connexion BDD."
fi

echo "🌐 Lancement du serveur Web HTTP Laravel sur 0.0.0.0:$PORT ..."
exec php -S 0.0.0.0:$PORT -t public public/index.php
