# 🚀 GUIDE PAS-À-PAS : CONFIGURER ET ACTIVER VOTRE COMPTE PAYDUNYA DANS LARAVEL 12

Félicitations pour la création de votre compte PayDunya ! Voici les **5 étapes précises** pour récupérer vos clés API, configurer l'URL de notification automatique (IPN) et activer les paiements Mobile Money / Wave / CB dans votre application de pronostics sportifs.

---

## 🔑 Étape 1 : Récupérer vos 3 Clés API dans le Tableau de Bord PayDunya

1. Connectez-vous sur votre espace marchand : **[https://app.paydunya.com/](https://app.paydunya.com/)**
2. Dans le menu à gauche, cliquez sur **"Intégration API"** (ou allez dans **"Mon Compte" -> "Clés API / Paramètres d'intégration"**).
3. Cliquez sur **"Créer une nouvelle application"** (ou **"Nouvelle Clé API"**) :
   - **Nom de l'application** : `Pronostics Sportifs VIP App`
   - **URL de l'application** : `https://pronostics-sportifs.pro`
4. PayDunya va vous afficher vos **3 identifiants officiels** (pour le mode *TEST* et le mode *LIVE*) :
   - **`Clé Principale (MasterKey)`** : Chaîne unique identifiant votre compte marchand.
   - **`Clé Privée (PrivateKey)`** : Clé secrète (il existe une *PrivateKey Test* et une *PrivateKey Live*).
   - **`Jeton (Token)`** : Le jeton d'authentification de votre application.

---

## 🌐 Étape 2 : Configurer l'URL IPN (Instant Payment Notification)

C'est l'étape la plus importante pour que l'abonnement VIP (2000 FCFA) soit **activé automatiquement** dans MySQL après le paiement du client sur son mobile :

1. Dans les paramètres d'intégration de votre application sur le tableau de bord PayDunya, cherchez la rubrique **"IPN URL"** (ou **"URL de Notification / Callback"**).
2. Saisissez l'adresse exacte de notre Webhook Laravel 12 :
   ```
   https://api.pronostics-sportifs.pro/api/v1/paydunya/ipn
   ```
   *(Remplacez `api.pronostics-sportifs.pro` par votre vrai nom de domaine ou adresse IP serveur si différent).*
3. **URL de retour succès** (Return URL) :
   ```
   https://api.pronostics-sportifs.pro/api/v1/paydunya/return
   ```
4. **URL d'annulation** (Cancel URL) :
   ```
   https://api.pronostics-sportifs.pro/api/v1/paydunya/cancel
   ```

---

## ⚙️ Étape 3 : Insérer vos Clés dans le Fichier `backend/.env` de Laravel

Dans votre espace de travail `/home/user/backend/`, ouvrez votre fichier **`.env`** (à partir de `.env.example`) et insérez vos clés PayDunya :

```env
# =====================================================================
# CONFIGURATION PAYDUNYA API (MODE TEST OU LIVE)
# =====================================================================
PAYDUNYA_MASTER_KEY="collez_ici_votre_master_key"
PAYDUNYA_PRIVATE_KEY="collez_ici_votre_private_key_test_ou_live"
PAYDUNYA_TOKEN="collez_ici_votre_token"

# Choisissez 'test' pour tester en mode Sandbox, ou 'live' pour les vrais paiements
PAYDUNYA_MODE="test"

PAYDUNYA_IPN_URL="https://api.pronostics-sportifs.pro/api/v1/paydunya/ipn"
PAYDUNYA_RETURN_URL="https://api.pronostics-sportifs.pro/api/v1/paydunya/return"
PAYDUNYA_CANCEL_URL="https://api.pronostics-sportifs.pro/api/v1/paydunya/cancel"
PAYDUNYA_CURRENCY="XOF"
```

---

## 🧪 Étape 4 : Tester votre Premier Paiement en Mode Sandbox (`test`)

Avant d'encaisser de l'argent réel, testez le flux de bout en bout :
1. Assurez-vous que `PAYDUNYA_MODE="test"` est activé dans le fichier `.env`.
2. Dans le tableau de bord PayDunya (section **"Sandbox / Données de Test"**), récupérez les numéros de téléphone de test fournis par PayDunya (ex : pour Orange Money Burkina Faso ou Sénégal).
3. Sur votre application mobile Flutter (ou sur le client web `user_app/index.html`), lancez la souscription à l'offre **VIP (2000 FCFA)** via PayDunya.
4. Simulez la validation du paiement avec le numéro de test :
   - Notre API appellera l'environnement Sandbox de PayDunya.
   - PayDunya notifiera `POST /api/v1/paydunya/ipn`.
   - L'abonnement de votre utilisateur de test passera instantanément à **`ACTIVE`** !

---

## 🚀 Étape 5 : Passer en Production (Mode `live`)

Dès que votre test est validé et que vous souhaitez encaisser vos vrais abonnés :
1. Dans le tableau de bord PayDunya, soumettez vos documents de conformité (KYC) si ce n'est pas encore fait (CNIB / RCCM / IFU) pour débloquer le versement sur votre compte Orange Money ou bancaire au Burkina Faso.
2. Récupérez votre **`PrivateKey LIVE`** (Clé privée de production).
3. Dans votre fichier **`.env`**, remplacez :
   ```env
   PAYDUNYA_PRIVATE_KEY="votre_private_key_live"
   PAYDUNYA_MODE="live"
   ```
4. Exécutez la commande de nettoyage du cache de configuration sur votre serveur Laravel :
   ```bash
   cd backend && php artisan config:clear && php artisan config:cache
   ```
   **Félicitations ! Votre application de pronostics sportifs encaisse désormais en direct via PayDunya (Orange Money, Moov Money, Wave et CB) !**
