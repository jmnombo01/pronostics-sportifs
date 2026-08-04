# 🎁 GUIDE DES MEILLEURES SOLUTIONS D'HÉBERGEMENT ET DE NOM DE DOMAINE 100% GRATUITS (POUR LARAVEL 12 & PAYDUNYA)

Pour héberger gratuitement votre backend **Laravel 12 API REST**, votre base de données **MySQL** et obtenir un **nom de domaine sécurisé avec HTTPS (SSL)** afin de recevoir les Webhooks de paiement de PayDunya / CinetPay, voici les **3 meilleures solutions gratuites à vie** en 2026.

---

## 🏆 OPTION 1 : LE DUO CLOUD MODERNE (RECOMMANDÉ & LE PLUS FIABLE)
**[Render.com](https://render.com) (Serveur Web Gratuit) + [Aiven.io](https://aiven.io) (MySQL 8.0 Gratuit à vie)**

C'est la solution cloud professionnelle gratuite la plus stable pour exécuter notre conteneur Docker Laravel 12 et recevoir les paiements 7j/7 et 24h/24.

### 1. Base de données MySQL 8.0 Gratuite sur [Aiven.io](https://aiven.io)
- Créez un compte gratuit sur [https://aiven.io](https://aiven.io) (sans carte bancaire requise).
- Créez un service **"MySQL Free Plan"** (1 CPU, 1 Go RAM, 5 Go de stockage gratuits à vie).
- Notez vos paramètres de connexion MySQL fournis par Aiven (`Host`, `Port`, `User`, `Password`, `Database`).

### 2. Hébergement Web & Nom de domaine HTTPS Gratuit sur [Render.com](https://render.com)
- Créez un compte gratuit sur [https://render.com](https://render.com) avec votre compte GitHub ou Git.
- Connectez votre dépôt GitHub contenant votre projet `backend/` (notre dossier Laravel 12 avec son `Dockerfile`).
- Créez un nouveau **"Web Service"** en sélectionnant le plan **"Free (0$/mois)"**.
- **Nom de domaine gratuit fourni par Render** :
  - Render vous attribue automatiquement une adresse professionnelle 100% gratuite sécurisée en HTTPS (SSL) !
  - *Exemple :* **`https://pronostics-sportifs-api.onrender.com`**
- Inserrez vos variables d'environnement dans l'interface Render :
  ```env
  APP_ENV=production
  APP_DEBUG=false
  APP_URL=https://pronostics-sportifs-api.onrender.com

  DB_CONNECTION=mysql
  DB_HOST=mysql-xxxx.aivencloud.com
  DB_PORT=26257
  DB_DATABASE=defaultdb
  DB_USERNAME=avnadmin
  DB_PASSWORD=mot_de_passe_fourni_par_aiven

  # VOS CLÉS PAYDUNYA / CINETPAY :
  PAYDUNYA_IPN_URL="https://pronostics-sportifs-api.onrender.com/api/v1/paydunya/ipn"
  PAYDUNYA_RETURN_URL="https://pronostics-sportifs-api.onrender.com/api/v1/paydunya/return"
  ```
- **Résultat** : Votre API Laravel est en ligne et votre URL IPN PayDunya est fonctionnelle !

---

## 🚀 OPTION 2 : HÉBERGEMENT PHP & MYSQL CLASSIQUE GRATUIT
**[InfinityFree.com](https://www.infinityfree.com) (PHP 8.3 + MySQL + Sous-domaine Gratuit)**

Si vous préférez un hébergement classique de type cPanel sans Docker ni ligne de commande :
1. Inscrivez-vous sur [https://www.infinityfree.com](https://www.infinityfree.com) (100% gratuit, sans publicité imposée, sans carte bancaire).
2. **Sous-domaine gratuit fourni** :
   - Vous pouvez choisir un nom gratuit parmi leurs domaines :
   - *Exemples :* **`https://pronostics-vip.free.nf`** ou **`https://prono-sportifs.rf.gd`**
3. **Certificat SSL HTTPS gratuit** :
   - Dans le panneau InfinityFree, allez sur **"Free SSL Certificates"** et installez un certificat SSL gratuit en 1 clic pour activer le `https://`.
4. **Base de données MySQL intégrée** :
   - Créez une base MySQL dans leur panneau phpMyAdmin et importez notre fichier de schéma :  
     `backend/database/schema.sql`.
5. **Configuration de l'URL dans PayDunya** :
   - Dans votre tableau de bord PayDunya, vous inscrirez simplement :  
     `https://pronostics-vip.free.nf/api/v1/paydunya/ipn`

---

## ⚡ OPTION 3 : VPS LINUX DÉDIÉ GRATUIT À VIE
**[Oracle Cloud Always Free Tier](https://www.oracle.com/cloud/free/)**

C'est l'offre gratuite la plus puissante au monde si vous avez un minimum de compétences système (ou si vous utilisez notre fichier `docker-compose.yml`) :
- **Ce qui est gratuit à vie** :
  - 2 serveurs virtuels (VPS) Linux autonomes.
  - 24 Go de RAM sur architecture ARM (ou 2 VM de 1 Go de RAM).
  - 200 Go de stockage NVMe.
  - Adresse IP publique fixe à vie !
- **Nom de domaine gratuit compatible (DuckDNS)** :
  - Reliez votre adresse IP Oracle Cloud à un nom de domaine gratuit chez [https://www.duckdns.org](https://www.duckdns.org) :
  - *Exemple :* **`https://pronostics-vip.duckdns.org`**
  - Installez le certificat HTTPS gratuit avec Let's Encrypt / Certbot.

---

## 📋 RÉCAPITULATIF : QUELLE URL METTRE SUR PAYDUNYA DÈS AUJOURD'HUI ?

Si vous choisissez **Render.com (Option 1)** ou **InfinityFree (Option 2)**, vous obtiendrez votre adresse en moins de 15 minutes. C'est elle que vous copierez dans votre compte PayDunya :

```
URL IPN (Webhook) : https://votre-nom-gratuit.onrender.com/api/v1/paydunya/ipn
URL de Retour     : https://votre-nom-gratuit.onrender.com/api/v1/paydunya/return
```

*Ces sous-domaines officiels sécurisés (HTTPS) sont 100% reconnus et acceptés par les serveurs de paiement PayDunya et CinetPay !*
