# 📋 FEUILLE DE ROUTE FINALE : CE QU'IL VOUS RESTE À FAIRE

Votre projet logiciel est **développé à 100%, testé et en ligne sur votre GitHub** (`github.com/jmnombo01/pronostics-sportifs`).

Voici la checklist des **quelques actions opérationnelles et administratives (15 à 30 minutes au total)** qu'il vous reste à réaliser pour commencer à encaisser vos premiers abonnés :

---

## 1. ☁️ Côté Serveur & Base de Données (Mise en ligne permanente)

- [ ] **Activer votre serveur sur Render.com (3 minutes)**
  - Allez sur **[https://dashboard.render.com/blueprints](https://dashboard.render.com/blueprints)**.
  - Cliquez sur **"New Blueprint Instance"** et choisissez le dépôt `jmnombo01/pronostics-sportifs`.
  - Cliquez sur **"Apply"** : Render crée votre serveur gratuit à vie avec SSL HTTPS.
- [ ] **Relier une base MySQL gratuite sur Aiven.io (5 minutes)**
  - Créez une base gratuite sur **[https://aiven.io](https://aiven.io)**.
  - Dans les variables d'environnement de Render, renseignez vos identifiants MySQL (`DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`).
  - Exécutez la commande d'initialisation dans la console Render :
    ```bash
    php artisan migrate --seed --force
    ```

---

## 2. 💳 Côté Paiements (PayDunya / CinetPay)

- [ ] **Vérifier l'adresse IPN dans votre tableau de bord PayDunya (2 minutes)**
  - Dans votre compte PayDunya -> *Intégration API*, vérifiez que l'URL d'IPN est bien celle de votre serveur :
    ```
    https://pronostics-api-server.onrender.com/api/v1/paydunya/ipn
    ```
- [ ] **Soumettre votre pièce d'identité (KYC) sur PayDunya**
  - Envoyez votre CNIB ou RCCM dans la section *Conformité* de PayDunya afin de pouvoir transférer les abonnements encaissés (2000 FCFA / client) directement vers votre **compte Orange Money, Moov Money ou bancaire au Burkina Faso**.
- [ ] **Passer en Mode LIVE (`PAYDUNYA_MODE="live"`)**
  - Dès que vos tests sont concluants, remplacez la clé de test par la clé Live de production.

---

## 3. 📲 Côté Application Mobile Flutter (`flutter_app/`)

- [ ] **Mettre à jour l'URL de votre serveur dans le code mobile**
  - Dans le fichier `flutter_app/lib/core/constants/api_constants.dart`, remplacez l'adresse d'exemple par la véritable URL de votre serveur Render :
    ```dart
    static const String baseUrl = 'https://pronostics-api-server.onrender.com/api/v1';
    ```
- [ ] **Générer le fichier de publication Android (`.aab`)**
  - Sur votre ordinateur, dans le dossier `flutter_app/`, lancez :
    ```bash
    flutter build appbundle --release
    ```
- [ ] **Publier sur Google Play Store (Android)**
  - Déposez le fichier `.aab` généré sur la [Google Play Console](https://play.google.com/console) pour le rendre disponible en téléchargement à vos abonnés.

---

## 4. 👑 Côté Activité (Votre rôle au quotidien !)

- [ ] **Publier vos pronostics chaque jour depuis le Tableau de Bord Admin (`/admin`)**
  - Sélectionnez vos matchs et créez vos combinés (**⚡ Côte 5**, **👑 Côte 10**, **💎 Côte 50**, **📈 Montante**).
  - Cliquez sur le bouton **"Publier"** :  
    **Cela envoie automatiquement une notification push instantanée sur les téléphones de tous vos abonnés !**
