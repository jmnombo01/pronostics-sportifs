# GUIDE DE DÉPLOIEMENT EN PRODUCTION - PRONOSTICS SPORTIFS

Ce guide explique comment mettre en production le backend Laravel 12 (avec Nginx, MySQL, Supervisor pour les files d'attente, SSL via Let's Encrypt), l'intégration CinetPay en mode LIVE, Firebase FCM pour les push notifications et la publication de l'application mobile Flutter sur Android Google Play & iOS App Store.

---

## 1. Déploiement du Backend Laravel 12

### Prérequis Serveur (Linux Ubuntu 24.04 LTS / Debian 12)
- PHP 8.3 ou supérieur (avec extensions : `php-mysql`, `php-mbstring`, `php-xml`, `php-curl`, `php-zip`, `php-gd`, `php-bcmath`)
- MySQL 8.0 ou MariaDB 10.11+
- Nginx & Certbot (SSL Let's Encrypt)
- Composer & Git

### Configuration du Serveur Web Nginx (`/etc/nginx/sites-available/pronostics-api`)
```nginx
server {
    listen 80;
    server_name api.pronostics-sportifs.pro;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.pronostics-sportifs.pro;
    root /var/www/pronostics-api/public;
    index index.php;

    ssl_certificate /etc/letsencrypt/live/api.pronostics-sportifs.pro/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.pronostics-sportifs.pro/privkey.pem;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }
}
```

### Installation du Code & Base de données
```bash
cd /var/www/
git clone https://github.com/your-org/pronostics-backend.git pronostics-api
cd pronostics-api
composer install --optimize-autoloader --no-dev
cp .env.example .env
php artisan key:generate
# Configurer MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD dans .env
php artisan migrate --force --seed
php artisan config:cache
php artisan route:cache
php artisan view:cache
chown -R www-data:www-data storage bootstrap/cache
```

---

## 2. Configuration CinetPay (Mode LIVE)

Dans votre fichier `.env` en production :
```env
CINETPAY_API_KEY=YOUR_LIVE_API_KEY
CINETPAY_SITE_ID=YOUR_LIVE_SITE_ID
CINETPAY_SECRET_KEY=YOUR_LIVE_SECRET_KEY
CINETPAY_NOTIFY_URL=https://api.pronostics-sportifs.pro/api/v1/cinetpay/webhook
CINETPAY_RETURN_URL=https://api.pronostics-sportifs.pro/api/v1/cinetpay/return
```

---

## 3. Configuration Firebase Cloud Messaging (FCM)

1. Connectez-vous sur la console Firebase (console.firebase.google.com).
2. Créez votre projet **Pronostics-Sportifs**.
3. Dans **Paramètres > Comptes de service**, générez une clé privée JSON (`firebase_credentials.json`).
4. Déposez ce fichier sur votre serveur sous `/var/www/pronostics-api/storage/app/firebase_credentials.json` et configurez `.env` :
```env
FCM_PROJECT_ID=pronostics-sportifs-app
FCM_CREDENTIALS_PATH=storage/app/firebase_credentials.json
```

---

## 4. Compilation & Publication Flutter (Android & iOS)

### Android (Google Play Store)
```bash
cd flutter_app
# 1. Configurer la clé de signature (android/key.properties)
# 2. Compiler en App Bundle release
flutter build appbundle --release --obfuscate --split-debug-info=./build/app/outputs/symbols
```
Déposez le fichier `.aab` généré sur la Google Play Console.

### iOS (App Store Connect)
```bash
cd flutter_app/ios
pod install --repo-update
cd ..
flutter build ipa --release
```
Ouvrez le projet `Runner.xcworkspace` dans Xcode et soumettez l'archive via App Store Connect.
