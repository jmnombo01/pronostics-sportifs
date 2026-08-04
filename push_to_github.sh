#!/usr/bin/env bash
set -e

REPO_URL=$1

if [ -z "$REPO_URL" ]; then
    echo "❌ Erreur : Veuillez fournir l'URL du dépôt GitHub (ex: https://github.com/votre-compte/votre-repo.git ou avec jeton https://TOKEN@github.com/votre-compte/votre-repo.git)"
    exit 1
fi

echo "🚀 Envoi automatique de l'intégralité du projet vers GitHub : $REPO_URL ..."
git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"
git branch -M main
git push -u origin main --force

echo "✅ =================================================================="
echo "✅ TOUT LE PROJET A ÉTÉ POUSSÉ SUR GITHUB AVEC SUCCÈS !"
echo "✅ Allez maintenant sur https://dashboard.render.com/blueprints"
echo "✅ et sélectionnez votre dépôt pour lancer le serveur gratuit !"
echo "✅ =================================================================="
