# ARCHITECTURE DU PROJET - PRONOSTICS SPORTIFS VIP & MONTANTE

Ce document décrit l'architecture technique globale, le schéma de la base de données, la logique de contrôle d'accès (abonnement & essai gratuit 48h), le cycle de vie des paiements CinetPay et des notifications push Firebase Cloud Messaging (FCM).

---

## 1. Vue d'Ensemble Technique

```
+------------------------------------------------------------------------------------+
|                         CLIENTS APPLICATIONS                                       |
|                                                                                    |
|   +------------------------------------+    +----------------------------------+   |
|   |         Flutter Mobile App         |    |      Web Admin Dashboard         |   |
|   |  (Android & iOS - Material 3)      |    |       (HTML5 / CSS / JS)         |   |
|   |  - Riverpod State Management       |    |       - Gestion Pronostics       |   |
|   |  - GoRouter & Dio Interceptors     |    |       - KPIs Chiffre d'affaires  |   |
|   +-----------------+------------------+    +-----------------+----------------+   |
+---------------------|-----------------------------------------|--------------------+
                      |                                         |
                      | HTTPS / REST JSON + Bearer Token        | HTTPS / REST JSON
                      v                                         v
+------------------------------------------------------------------------------------+
|                         LARAVEL 12 API GATEWAY & CORE                              |
|                                                                                    |
|   +----------------------------------------------------------------------------+   |
|   |                            Security Layer                                  |   |
|   |   - Laravel Sanctum (JWT/Bearer Token Auth)                                |   |
|   |   - Middlewares: CheckSubscriptionAccess, AdminMiddleware, XSS, CSRF       |   |
|   |   - Rate Limiting (60 req/min API, 5 req/min Auth)                         |   |
|   +-------------------------------------+--------------------------------------+   |
|                                         |                                          |
|   +-------------------------------------v--------------------------------------+   |
|   |                            MVC Architecture                                |   |
|   |   - Controllers: Auth, Predictions, Subscriptions, CinetPay, Admin         |   |
|   |   - Services: CinetPayService, FcmNotificationService                      |   |
|   |   - Models: User, Prediction, SubscriptionPlan, UserSubscription, Payment  |   |
|   +-------------------------------------+--------------------------------------+   |
+-----------------------------------------|------------------------------------------+
                                          |
        +---------------------------------+---------------------------------+
        |                                 |                                 |
        v                                 v                                 v
+---------------+                +-----------------+              +------------------+
|  MySQL DB     |                |  CinetPay API   |              | Firebase FCM     |
|  - Users      |                |  - Mobile Money |              | - Push Notify    |
|  - Subscriptions               |  - Carte Banc.  |              |   au nouveau     |
|  - Predictions|                |  - Webhook Secu |              |   pronostic      |
+---------------+                +-----------------+              +------------------+
```

---

## 2. Schéma de la Base de Données (MySQL)

```
+------------------------+          +---------------------------+
|         users          |          |     subscription_plans    |
+------------------------+          +---------------------------+
| id (PK)                |          | id (PK)                   |
| last_name              |          | code ('VIP', 'MONTANTE')  |
| first_name             |          | name                      |
| phone                  |          | price (2000 FCFA)         |
| email                  |          | duration_days (30 / 7)    |
| password               |          | description               |
| is_admin               |          +-------------+-------------+
| subscription_status    |                        |
| subscription_expires_at|                        |
| free_trial_expires_at  |                        |
| created_at (inscription)                  | 1:N
+-----------+------------+                        |
            |                                     |
            | 1:N                                 v
            |                        +---------------------------+
            +----------------------->|     user_subscriptions    |
            |                        +---------------------------+
            |                        | id (PK)                   |
            |                        | user_id (FK)              |
            |                        | subscription_plan_id (FK) |
            |                        | status ('ACTIVE', 'EXPIRED')|
            |                        | starts_at                 |
            |                        | expires_at                |
            |                        +-------------+-------------+
            |                                      |
            | 1:N                                  | 1:N
            v                                      v
+------------------------+               +---------------------------+
|       payments         |               |        predictions        |
+------------------------+               +---------------------------+
| id (PK)                |               | id (PK)                   |
| user_id (FK)           |               | title, competition, country|
| subscription_plan_id(FK)               | championship, match_date  |
| transaction_id         |               | match_time                |
| cinetpay_token         |               | home_team, away_team      |
| amount                 |               | type ('MONTANTE','COTE_5',|
| currency ('XOF')       |               |       'COTE_10','COTE_50')|
| status ('PENDING',     |               | odds, confidence (1-5), selections_json (JSON) |
|  'ACCEPTED','FAILED')  |               | analysis, image_url       |
| payment_method         |               | status ('PENDING','WON',  |
| raw_response           |               |         'LOST','VOID')    |
+------------------------+               | is_published, published_at|
                                         +---------------------------+
```

---

## 3. Logique d'Accès aux Catégories & Essai Gratuit (48 Heures)

Le contrôle d'accès est géré de façon centralisée par le middleware `CheckSubscriptionAccess.php` et par le modèle `User.php`.

### Tableau de Droits d'Accès par Type de Pronostic

| Catégorie de Pronostic | Accès Essai Gratuit (<48h) | Abonné VIP (2000 FCFA/mois) | Abonné Montante (2000 FCFA/semaine) | Statut Expiré (>48h et non-abonné) |
| :--- | :---: | :---: | :---: | :---: |
| **Côte 5** |  Autorisé (48h max) |  Autorisé |  Refusé |  Bloqué (Affichage "🔒 Réservé aux abonnés") |
| **Côte 10** |  Refusé |  Autorisé |  Refusé |  Bloqué |
| **Côte 50 (Pronostic semaine)** |  Refusé |  Autorisé (Cote min 50) |  Refusé |  Bloqué |
| **Montante** |  Refusé |  Refusé |  Autorisé (2000 FCFA/sem) |  Bloqué |

### Règle d'Essai Gratuit 48 Heures (Côte 5 uniquement)
1. Lors de l'inscription (`AuthController@register`), le système enregistre :
   - `created_at` = date d'inscription
   - `free_trial_expires_at` = `now()->addHours(48)`
   - `subscription_status` = `FREE_TRIAL`
2. Tant que `now() <= free_trial_expires_at`, l'utilisateur accède librement aux pronostics de la catégorie **Côte 5**.
3. Au-delà de 48 heures sans abonnement VIP actif :
   - L'accès est révoqué automatiquement par le serveur (code HTTP `403 Forbidden` avec un payload JSON `{ "code": "SUBSCRIPTION_REQUIRED", "message": "Votre période d'essai de 48h est expirée..." }`).
   - Le frontend Flutter affiche une modale / écran de souscription invitant à s'abonner pour 2000 FCFA/mois ou 2000 FCFA/semaine.

---

## 4. Cycle de Vie du Paiement CinetPay & Sécurité Webhook

### Flux d'Intégration CinetPay (Mobile Money & Carte Bancaire)

```
[Flutter Mobile]            [Laravel API Backend]             [CinetPay API & Webhook]
       |                             |                                    |
       | 1. POST /api/v1/subscribe   |                                    |
       |   (plan_code: 'VIP')        |                                    |
       |---------------------------->|                                    |
       |                             | 2. Initialisation CinetPay         |
       |                             |    (POST /v1/?method=payment)      |
       |                             |----------------------------------->|
       |                             | 3. Retour URL / Token paiement     |
       |                             |<-----------------------------------|
       | 4. JSON { payment_url }     |                                    |
       |<----------------------------|                                    |
       |                                                                  |
       | 5. Ouvre la Webview / SDK CinetPay (Mobile Money: Orange/MTN/Moov ou Carte CB)
       |----------------------------------------------------------------->|
       |                                                                  |
       |                           6. Notification Asynchrone (WEBHOOK)    |
       |                             |   POST /api/v1/cinetpay/webhook    |
       |                             |<-----------------------------------|
       |                             |  - Vérification signature HMAC     |
       |                             |  - Vérification statut du paiement |
       |                             |  - Activation de l'abonnement SQL  |
       |                             |  - Réponse HTTP 200 OK             |
       |                             |----------------------------------->|
       | 7. GET /api/v1/profile      |                                    |
       |   (Statut mis à jour !)     |                                    |
       |---------------------------->|                                    |
```

### Protection Idempotence & HMAC Webhook
- **Idempotence** : Chaque paiement utilise un `transaction_id` unique généré par Laravel (`CP-YYYYMMDD-XXXXXX`). Si CinetPay envoie deux notifications pour la même transaction, la seconde est ignorée sans dupliquer l'abonnement.
- **Signature & Vérification CinetPay** : Le webhook vérifie via le `site_id` et la clé secrète en appelant l'API de vérification CinetPay (`POST /v1/?method=checkPayStatus`) avant de marquer le paiement comme `ACCEPTED`.

---

## 5. Architecture Push Notifications Firebase Cloud Messaging (FCM)

- Lorsqu'un administrateur publie ou programme un pronostic dans le tableau de bord :
  1. Le contrôleur `AdminPredictionController@publish` met à jour `is_published = true`.
  2. Il déclenche le service `FcmNotificationService::sendPredictionNotification($prediction)`.
  3. Ce service envoie un payload FCM aux topics concernés (`topic_all`, `topic_vip`, `topic_montante`) avec le titre du match et la cote, permettant au client Flutter de recevoir une notification riche avec badge et deep-link direct vers la fiche de pronostic.
