# 🐬 GUIDE EN 3 CLICS : CRÉER VOTRE BASE MYSQL GRATUITE SUR AIVEN.IO

Pour relier une base de données cloud **MySQL 8.0 gratuite à vie**, voici comment procéder en 45 secondes :

---

## 1. Créez le service gratuit sur Aiven
1. Allez sur **[https://console.aiven.io/signup](https://console.aiven.io/signup)** *(connectez-vous avec Google ou GitHub pour aller plus vite)*.
2. Cliquez en haut à droite sur le bouton bleu **"Create service"** (Créer un service).
3. Sélectionnez :
   - **Service type** : **`MySQL`**
   - **Cloud provider** : Libre (ex: Google Cloud ou AWS Europe).
   - **Service plan** : Sélectionnez la case **`Free`** *(0$/mois à vie, 5 Go de stockage, 1 CPU, sans carte bancaire)*.
4. Cliquez en bas sur **"Create free service"**.

---

## 2. Copiez votre "Service URI" (Lien de connexion MySQL)
Sur la page de votre nouveau service MySQL Aiven, regardez dans la section **"Connection information"** :
- Vous y verrez un champ appelé **`Service URI`** (ou *MySQL URI*).
- Cliquez sur l'icône de copie pour copier ce lien. Il ressemble à ceci :
  ```text
  mysql://avnadmin:AVNS_xxxxxxxxx@mysql-xxxx-votre-compte.aivencloud.com:26257/defaultdb?ssl-mode=REQUIRED
  ```

---

## 3. Collez-moi ce lien ici !
Dès que vous me collez votre **Service URI** dans notre conversation :
- J'exécute automatiquement le script **`connect_aiven_db.py`** (que j'ai déjà créé et poussé sur votre GitHub).
- Je me connecte à votre serveur Aiven.
- J'y importe en 2 secondes vos 7 tables de base de données et l'ensemble de vos pronostics combinés (Côte 5, 10, 50).
- Je synchronise vos identifiants sur votre GitHub !
