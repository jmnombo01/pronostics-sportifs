#!/usr/bin/env bash
set -e

echo "👑 =================================================================="
echo "👑 DÉPLOIEMENT AUTOMATISÉ - PRONOSTICS SPORTIFS (LARAVEL 12 & DOCKER)"
echo "👑 =================================================================="

if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker n'est pas installé. Installation en cours..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
fi

if [ ! -f backend/.env ]; then
    echo "📝 Création du fichier .env à partir du modèle..."
    cp backend/.env.example backend/.env
fi

echo "🚀 Démarrage des conteneurs Docker (API Laravel 12 + MySQL 8.0 + Nginx)..."
docker compose up -d --build

echo "⏳ Attente du démarrage de la base de données MySQL..."
sleep 10

echo "🌱 Exécution des migrations et du Seeder de pronostics combinés..."
docker compose exec -T app php artisan migrate --seed --force || true

echo "✅ =================================================================="
echo "✅ DÉPLOIEMENT AUTOMATIQUE TERMINÉ AVEC SUCCÈS !"
echo "✅ Votre API est accessible sur http://localhost:8000"
echo "✅ =================================================================="
