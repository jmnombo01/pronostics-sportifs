#!/usr/bin/env bash
set -e

echo "🐸 =================================================================="
echo "🐸 COMPILATION OFFICIELLE GOOGLE PLAY STORE - FROGAZZ SPORT ANALYSE"
echo "🐸 =================================================================="

if ! command -v flutter >/dev/null 2>&1; then
    echo "❌ Flutter n'est pas installé sur cet ordinateur. Veuillez installer le SDK Flutter."
    exit 1
fi

echo "📦 Nettoyage et récupération des dépendances..."
flutter clean
flutter pub get

echo "🏗️ Compilation du fichier Android App Bundle (.aab) en mode Release..."
flutter build appbundle --release --obfuscate --split-debug-info=./build/app/outputs/symbols

echo "✅ =================================================================="
echo "✅ COMPILATION TERMINÉE AVEC SUCCÈS !"
echo "✅ Votre fichier de publication pour Google Play Store se trouve ici :"
echo "✅ --> build/app/outputs/bundle/release/app-release.aab"
echo "✅ =================================================================="
