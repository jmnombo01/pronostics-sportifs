# 👑 PRONOSTICS SPORTIFS - APPLICATION MOBILE & BACKEND LARAVEL 12

**Plateforme professionnelle de pronostics sportifs avec système d'abonnement VIP (2000 FCFA/mois) & Montante (2000 FCFA/semaine), essai gratuit 48h sur Côte 5, intégration de paiement CinetPay (Mobile Money & Carte Bancaire) et notifications push Firebase Cloud Messaging (FCM).**

---

## 🌟 Vue d'ensemble du Livrable

Ce projet complet est prêt pour une mise en production professionnelle. Il a été structuré selon une architecture **MVC / Clean Architecture** robuste avec une séparation claire entre l'API backend sécurisée, l'application mobile multiplateforme et le tableau de bord d'administration :

```
/home/user/
├── backend/                  # API REST Laravel 12 & MySQL
│   ├── app/Models/           # Eloquent Models (User, Prediction, SubscriptionPlan, Payment...)
│   ├── app/Services/         # Services CinetPay API & Firebase Cloud Messaging (FCM)
│   ├── app/Http/Controllers/ # Contrôleurs API REST v1 & Admin RBAC
│   ├── app/Http/Middleware/  # CheckSubscriptionAccess (Essai gratuit 48h & Verrouillage VIP)
│   ├── database/             # Schéma SQL complet, Migrations Laravel, Seeders (15+ pronos)
│   └── tests/Feature/        # Tests automatisés PHPUnit (Auth, Abonnement 48h, Webhook CinetPay)
├── flutter_app/              # Application Mobile Flutter (Android & iOS - Material 3)
│   ├── lib/core/             # Thème (Noir #0A0A0B, Blanc, Or #D4AF37, Vert #00C853), Dio Client
│   ├── lib/models/           # Modèles de données avec isLocked pour la gestion d'accès
│   ├── lib/providers/        # Riverpod State Management (Auth, Pronostics, CinetPay, Thème)
│   ├── lib/services/         # API Service & FCM Notification Listener
│   └── lib/ui/screens/       # Écrans Accueil, Pronostic détail (avec cadenas 🔒), Abonnements
├── admin_dashboard/          # Tableau de Bord Administrateur Interactif (HTML5 / CSS / JS)
│   └── index.html            # Interface de gestion des Pronostics, KPIs & Simulateur Webhook
└── docs/                     # Documentation Technique
    ├── ARCHITECTURE.md       # Architecture détaillée, règles d'accès 48h & diagrammes
    ├── API_REFERENCE.md      # Documentation des endpoints REST
    ├── openapi.yaml          # Spécification OpenAPI 3.0
    ├── swagger-ui.html       # Visualiseur interactif Swagger UI
    └── DEPLOYMENT_GUIDE.md   # Guide de déploiement (Nginx, MySQL, Let's Encrypt, CinetPay LIVE)
```

---

## 🔒 Logique d'Abonnements & Essai Gratuit 48h

### 1. Grille d'Accès aux Catégories & Combinés Multi-Matchs
En pronostics sportifs, une **Côte 5** (tout comme une Côte 10 ou Côte 50) correspond à un **ticket combiné / accumulateur de plusieurs matchs** (ex: un combiné de 3 matchs dont les cotes multipliées donnent ~5.18).  
Le schéma de base de données intègre le champ **`selections_json`**, qui stocke la liste détaillée des rencontres composant chaque ticket.

| Catégorie | Description du Ticket | Essai Gratuit (<48h) | Abonnement VIP (2000 FCFA/m) | Abonnement Montante (2000 FCFA/s) | Statut Expiré (>48h) |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **⚡ Côte 5** | **Combiné 2 à 4 matchs** (Cote totale ~5.00) | **Autorisé (48h max)** | **Autorisé** | Refusé | **Bloqué (Cadenas 🔒)** |
| **👑 Côte 10** | **Combiné 3 à 5 matchs** (Cote totale ~10.00) | Refusé | **Autorisé** | Refusé | **Bloqué** |
| **💎 Côte 50** | **Méga Combiné Semaine** (6+ matchs, Cote ≥ 50) | Refusé | **Autorisé** | Refusé | **Bloqué** |
| **📈 Montante** | **Stratégie progressive** (1 ou 2 matchs / étape) | Refusé | Refusé | **Autorisé** | **Bloqué** |

### 2. Période d'Essai de 48 Heures (Côte 5)
- Dès l'inscription via `/api/v1/auth/register`, le compte utilisateur est créé avec `free_trial_expires_at = now()->addHours(48)` et le statut `FREE_TRIAL`.
- Pendant les 48 premières heures, le middleware `CheckSubscriptionAccess` autorise l'accès à la catégorie **Côte 5**.
- Après 48 heures sans souscription VIP, l'accès est révoqué automatiquement : le backend renvoie le code `SUBSCRIPTION_REQUIRED` avec `is_locked: true`, et l'application mobile affiche l'encart **"🔒 Réservé aux abonnés. Abonnez-vous pour voir l'analyse"**.

---

## 💳 Intégration CinetPay & Alternative PayDunya (Multi-Passerelles)

L'application intègre **deux passerelles de paiement africaines majeures** afin de garantir un taux d'encaissement de 100% :
1. **CinetPay (Passerelle principale)** : Prise en charge d'Orange Money, MTN Mobile Money, Moov Money, Airtel et Carte Bancaire avec validation Webhook HMAC.
2. **PayDunya (Alternative & Fallback natif)** : Prise en charge d'Orange Money, Moov, **Wave**, Free Money et Cartes Bancaires avec système d'**IPN (Instant Payment Notification)** sécurisé (`PayDunyaService.php`).

*Consultez le guide comparatif complet et la configuration multi-passerelles dans **`docs/PAYDUNYA_VS_CINETPAY.md`**.*

---

## 📲 Notifications Push Firebase Cloud Messaging (FCM)

- Lorsqu'un administrateur publie un pronostic, le service `FcmNotificationService::sendPredictionNotification` émet une notification sur les topics (`topic_all`, `topic_vip`, `topic_montante`).
- L'application Flutter reçoit la notification avec le titre du match et sa cote, offrant un deep-linking vers la fiche de pronostic.

---

## 🚀 Guide de Démarrage Rapide

### 1. Tester le Tableau de Bord Admin (Directement dans le Viewer)
- Ouvrez le fichier `admin_dashboard/index.html` dans le visualiseur de l'espace de travail.
- Explorez les **KPIs en direct** (Chiffre d'affaires, utilisateurs, paiements du jour).
- Cliquez sur **"+ Nouveau Pronostic"** ou modifiez un match existant.
- Cliquez sur **"Simuler Webhook CinetPay"** pour tester le flux complet de paiement et d'activation.

### 2. Visualiser la Documentation Swagger API
- Ouvrez `docs/swagger-ui.html` pour consulter la documentation interactive OpenAPI 3.0.

### 3. Démarrer le Backend Laravel 12 en Local
```bash
cd backend
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

### 4. Lancer l'Application Flutter
```bash
cd flutter_app
flutter pub get
flutter run
```
