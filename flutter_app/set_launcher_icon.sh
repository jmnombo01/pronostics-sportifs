#!/usr/bin/env bash
# Applique l'icône grenouille 🐸 Frogazz Sport Analyse aux icônes Android (legacy + adaptive)
set -e

cd "$(dirname "$0")"

RES="android/app/src/main/res"

# 1. Copier les icônes legacy (fond sombre) et le foreground adaptatif (grenouille transparente)
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  cp -f "launcher_icons/mipmap-$d/ic_launcher.png" "$RES/mipmap-$d/ic_launcher.png"
  cp -f "launcher_icons/mipmap-$d/ic_launcher_foreground.png" "$RES/mipmap-$d/ic_launcher_foreground.png"
done

# 2. Fond adaptatif sombre (#060907) au lieu du blanc par défaut
for f in "$RES/values/ic_launcher_background.xml" "$RES/values/colors.xml" "$RES/mipmap-anydpi-v26/ic_launcher.xml"; do
  if [ -f "$f" ]; then
    sed -i 's/#[fF][fF][fF][fF][fF][fF]/#060907/g' "$f"
  fi
done

echo "✅ Icône grenouille Frogazz appliquée (legacy + adaptive, fond #060907)"
