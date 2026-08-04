# 💳 GUIDE COMPLET : CRÉER ET CONFIGURER SON COMPTE MARCHAND CINETPAY (BURKINA FASO & ZONE UEMOA)

Ce guide pas-à-pas vous accompagne de la création de votre compte marchand CinetPay jusqu'au branchement de vos clés API dans votre backend Laravel 12 afin d'encaisser par **Mobile Money** (Orange Money, MTN, Moov, Airtel) et **Carte Bancaire** (Visa / Mastercard).

---

## 📋 1. Prérequis & Documents Nécessaires (Burkina Faso / UEMOA)

Selon votre statut, préparez les documents KYC (Conformité) suivants au format PDF ou Photo nette :

### A. Si vous vous inscrivez en tant que Particulier / Entrepreneur Individuel :
- **Pièce d'identité valide** : CNIB (Carte Nationale d'Identité Burkinabè) ou Passeport.
- **Numéro de téléphone de réception** : Un compte Mobile Money au Burkina Faso (Orange Money, Moov Money, ou Telecel) sur lequel CinetPay versera vos fonds.
- **Adresse Email** et numéro de téléphone de contact (indicatif `+226`).

### B. Si vous vous inscrivez en tant qu'Entreprise Formelle (Recommandé) :
- **RCCM** (Registre du Commerce et du Crédit Mobilier).
- **IFU** (Identifiant Financier Unique).
- **CNIB / Passeport** du représentant légal / gérant.
- **RIB Bancaire** ou compte Mobile Money d'entreprise au Burkina Faso.

---

## 🚀 2. Étape par Étape : Inscription & Activation KYC

1. **Création du Compte sur le Portail CinetPay** :
   - Allez sur [https://app.cinetpay.com](https://app.cinetpay.com/) et cliquez sur **"Créer un compte"**.
   - Sélectionnez votre pays : **Burkina Faso (`BF`)**.
   - Saisissez vos nom, prénom, email, téléphone (`+226...`) et mot de passe.
2. **Validation Email & SMS** :
   - Vérifiez votre boîte de réception email (ou spams) et cliquez sur le lien de confirmation.
   - Validez le code de sécurité reçu par SMS.
3. **Soumission de votre dossier de conformité (KYC)** :
   - Une fois connecté à votre tableau de bord, cliquez sur **"Mon Compte"** (ou sur l'alerte rouge **"Compte non vérifié"**).
   - Déposez vos documents (CNIB/RCCM/IFU) dans l'onglet **"Documents KYC"**.
   - *Délai de vérification par CinetPay* : 24h à 48h ouvrées.
   - *Note* : En attendant la validation KYC pour le retrait des fonds, **vous pouvez immédiatement créer un Service et tester l'API en mode intégration !**

---

## 🔑 3. Création du "Service" (Marchand) et Récupération des Clés

1. Dans le menu latéral du tableau de bord CinetPay, cliquez sur **"Mes Services"** -> **"Nouveau Service"**.
2. Remplissez les informations de votre application :
   - **Nom du Service** : `Pronostics Sportifs VIP`
   - **Secteur d'activité** : Service en ligne / Abonnements sportifs.
   - **URL de l'application / site** : `https://pronostics-sportifs.pro` (ou l'URL de votre serveur).
3. Dès que le service est enregistré, cliquez sur **"Détails"** ou **"Clés API"** pour afficher vos **3 identifiants officiels** :
   - **`API_KEY`** : La clé API globale de votre compte marchand (ex: `1234567890.abcdefghijklm...`).
   - **`SITE_ID`** : L'identifiant à 6 ou 7 chiffres du service d'abonnement (ex: `654321`).
   - **`SECRET_KEY`** : La clé secrète pour sécuriser les notifications et vérifier la signature HMAC des webhooks.

---

## ⚙️ 4. Configuration des Clés dans votre Backend Laravel 12

Ouvrez le fichier de configuration de votre serveur sous **`backend/.env`** (à partir de `backend/.env.example`) et insérez vos identifiants à la section CinetPay :

```env
# =====================================================================
# CONFIGURATION CINETPAY API (MODE LIVE / PRODUCTION)
# =====================================================================
CINETPAY_API_KEY="VOTRE_API_KEY_CINETPAY_ICI"
CINETPAY_SITE_ID="VOTRE_SITE_ID_ICI"
CINETPAY_SECRET_KEY="VOTRE_SECRET_KEY_ICI"
CINETPAY_NOTIFY_URL="https://api.pronostics-sportifs.pro/api/v1/cinetpay/webhook"
CINETPAY_RETURN_URL="https://api.pronostics-sportifs.pro/api/v1/cinetpay/return"
CINETPAY_CURRENCY="XOF"
```

---

## 🔒 5. Règle d'Or : Vérifier l'Accessibilité du Webhook (`NOTIFY_URL`)

Pour que l'activation automatique de l'abonnement VIP (2000 FCFA/mois) ou Montante fonctionne de façon 100% autonome :
1. L'URL `CINETPAY_NOTIFY_URL` (**`https://api.pronostics-sportifs.pro/api/v1/cinetpay/webhook`**) doit être accessible **en public sur Internet** via HTTPS sans mot de passe ni blocage pare-feu.
2. Lorsque le client valide son paiement Orange Money, MTN ou Moov sur son téléphone, CinetPay appelle instantanément cette URL en tâche de fond.
3. Notre contrôleur **`CinetPayWebhookController@webhook`** vérifie la signature HMAC, marque la transaction comme **`ACCEPTED`** en base de données, et active l'abonnement de l'utilisateur !
