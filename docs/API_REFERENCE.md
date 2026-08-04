# RÉFÉRENCE DE L'API REST - PRONOSTICS SPORTIFS

Base URL : `https://api.pronostics-sportifs.pro/api/v1`  
Authentification : **Bearer Token (Laravel Sanctum)**  
Headers requis :
- `Accept: application/json`
- `Content-Type: application/json`
- `Authorization: Bearer <token>` (pour les routes protégées)

---

## 1. Authentification (`/auth`)

### `POST /auth/register`
Inscrit un nouvel utilisateur et démarre l'essai gratuit de 48h (Côte 5).
- **Body JSON** :
  ```json
  {
    "last_name": "Kaboré",
    "first_name": "Moussa",
    "phone": "+22670112233",
    "email": "moussa.kabore@example.com",
    "password": "Password123!",
    "password_confirmation": "Password123!"
  }
  ```
- **Réponse 201 Created** :
  ```json
  {
    "success": true,
    "message": "Inscription réussie. Vous bénéficiez de 48 heures d'essai gratuit sur la catégorie Côte 5.",
    "token": "1|abcdef123456789...",
    "user": {
      "id": 1,
      "last_name": "Kaboré",
      "first_name": "Moussa",
      "phone": "+22670112233",
      "email": "moussa.kabore@example.com",
      "subscription_status": "FREE_TRIAL",
      "free_trial_expires_at": "2026-08-05T14:00:00.000000Z",
      "created_at": "2026-08-03T14:00:00.000000Z"
    }
  }
  ```

### `POST /auth/login`
- **Body JSON** :
  ```json
  {
    "email": "moussa.kabore@example.com",
    "password": "Password123!"
  }
  ```
- **Réponse 200 OK** : Retourne l'objet user, son statut d'abonnement et le token.

### `POST /auth/forgot-password`
Génère un jeton ou envoie le lien de réinitialisation.
- **Body JSON** :
  ```json
  { "email": "moussa.kabore@example.com" }
  ```

### `POST /auth/logout`
Révoque le jeton Bearer de l'utilisateur actif.

### `GET /auth/profile`
Récupère les informations complètes du profil, l'état de l'abonnement en cours et la date d'expiration.

---

## 2. Pronostics (`/predictions`)

### `GET /predictions`
Retourne la liste des pronostics par catégorie et recherche.
- **Query Parameters optionnels** :
  - `type` : `'MONTANTE'`, `'COTE_5'`, `'COTE_10'`, `'COTE_50'`
  - `championship` : Ex: `'Ligue 1'`
  - `team` : Ex: `'Real Madrid'`
  - `match_date` : `'2026-08-03'`
  - `status` : `'PENDING'`, `'WON'`, `'LOST'`, `'VOID'`
- **Comportement de sécurité (Verrouillage Automatique)** :
  - Si l'utilisateur n'a pas accès (ex: il n'est pas VIP et demande une `COTE_10` ou son essai gratuit est expiré), l'API retourne le pronostic avec un champ `is_locked: true` et masque l'analyse détaillée et les conseils d'expert.
- **Exemple de réponse 200 OK** :
  ```json
  {
    "success": true,
    "data": [
      {
        "id": 10,
        "title": "Real Madrid vs Barcelone",
        "competition": "La Liga",
        "country": "Espagne",
        "championship": "La Liga",
        "match_date": "2026-08-04",
        "match_time": "20:00",
        "home_team": "Real Madrid",
        "away_team": "Barcelone",
        "type": "COTE_10",
        "odds": "10.50",
        "confidence": 5,
        "status": "PENDING",
        "is_locked": false,
        "analysis": "Match décisif en tête du championnat..."
      }
    ]
  }
  ```

### `GET /predictions/{id}`
Détail complet d'un pronostic. Si `is_locked == true`, retourne une erreur 403 HTTP ou un payload restreint invitant à s'abonner.

---

## 3. Abonnements & CinetPay (`/subscriptions`)

### `GET /subscriptions/plans`
Liste les 2 plans disponibles (`VIP` à 2000 FCFA/mois et `MONTANTE` à 2000 FCFA/semaine).

### `POST /subscriptions/subscribe`
Initialise un paiement via le SDK CinetPay.
- **Body JSON** :
  ```json
  {
    "plan_code": "VIP",
    "payment_method": "MOBILE_MONEY",
    "phone": "+22670112233",
    "promo_code": "WELCOME10"
  }
  ```
- **Réponse 200 OK** :
  ```json
  {
    "success": true,
    "transaction_id": "CP-20260803-889102",
    "amount": 2000,
    "currency": "XOF",
    "cinetpay_payment_url": "https://secure.cinetpay.com/payment/...",
    "cinetpay_token": "token_12345"
  }
  ```

### `POST /cinetpay/webhook`
Endpoint asynchrone notifié par CinetPay après chaque paiement (Mobile Money ou Carte Bancaire).
- Validation HMAC automatique.
- Active instantanément l'abonnement de l'utilisateur (VIP ou Montante) et prolonge la date d'expiration.

---

## 4. Historique (`/history`)

### `GET /history/predictions`
Historique des pronostics terminés (`WON`, `LOST`, `VOID`) pour consulter le bilan et les statistiques de réussite.

### `GET /history/payments`
Historique complet des transactions de paiement effectuées par l'utilisateur connecté.

### `GET /history/subscriptions`
Historique des souscriptions actives et passées.

---

## 5. Administration (`/admin`) *(Accès Réservé aux Admins - RBAC)*

### `GET /admin/dashboard/stats`
Retourne les indicateurs du tableau de bord :
- Nombre d'utilisateurs et nouveaux du jour
- Abonnés VIP et Abonnés Montante
- Paiements du jour et du mois
- Chiffre d'affaires cumulé en FCFA
- Nombre total de pronostics publiés

### `GET /admin/predictions`
Liste l'ensemble des pronostics (publiés, brouillons, programmés, archivés).

### `POST /admin/predictions`
Création d'un pronostic.
- Types : `'MONTANTE'`, `'COTE_5'`, `'COTE_10'`, `'COTE_50'`.
- Permet la publication immédiate ou la programmation à date fixe (`scheduled_at`).
- Envoie automatiquement une notification push Firebase (FCM) si `is_published = true`.

### `PUT /admin/predictions/{id}`
Modification globale d'un pronostic (changement d'état : `WON`, `LOST`, mise à jour cote/analyse).

### `POST /admin/predictions/{id}/publish`
Publie un pronostic en brouillon et déclenche le push FCM.

### `POST /admin/predictions/{id}/unpublish`
Dépublie le pronostic.

### `DELETE /admin/predictions/{id}`
Supprime ou archive un pronostic.
