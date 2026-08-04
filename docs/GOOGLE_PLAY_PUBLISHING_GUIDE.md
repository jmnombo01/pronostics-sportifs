# 🐸📲 GUIDE COMPLET : PUBLIER "FROGAZZ SPORT ANALYSE" SUR LE GOOGLE PLAY STORE

Ce guide pratique vous décrit les étapes précises pour signer, compiler et publier votre application mobile Flutter **Frogazz Sport Analyse** sur le Google Play Store.

---

## 📋 Étape 1 : Préparer votre compte Google Play Console

1. **Créer votre compte développeur** :
   - Allez sur **[https://play.google.com/console/signup](https://play.google.com/console/signup)**.
   - Frais d'inscription à vie : **25$ USD** (~15 000 FCFA), payables par carte bancaire.
   - Validez votre identité (CNIB ou Passeport) auprès de Google.
2. **Politique des 20 testeurs (pour les comptes individuels)** :
   - Si vous êtes inscrit en tant que particulier, Google requiert d'activer un **test fermé avec 20 testeurs pendant 14 jours** avant d'ouvrir la version publique.
   - *Astuce* : Invitez 20 amis ou membres de votre communauté sur WhatsApp à tester l'application pendant 2 semaines.

---

## 🛠️ Étape 2 : Configurer l'identifiant et l'icône de l'application

1. **Vérifier l'ID du package (Package Name)** :
   - Dans le projet mobile, votre identifiant unique professionnel est **`pro.frogazz.sportanalyse`** (défini sous `android/app/build.gradle`).
2. **Ajouter l'icône officielle de la grenouille 🐸** :
   - Assurez-vous que l'icône de l'application est bien placée dans `flutter_app/android/app/src/main/res/` (ou utilisez le package `flutter_launcher_icons` pour la générer sur toutes les résolutions).

---

## 🔐 Étape 3 : Créer votre clé de signature officielle (Keystore)

Pour que Google valide votre application, vous devez créer une clé numérique qui prouve que vous êtes l'auteur de l'application :

1. Sur votre ordinateur, ouvrez le terminal dans le dossier `flutter_app/android/` et lancez :
   ```bash
   keytool -genkey -v -keystore frogazz-upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias frogazz
   ```
2. Créez un fichier **`flutter_app/android/key.properties`** et indiquez vos mots de passe :
   ```properties
   storePassword=votre_mot_de_passe_keystore
   keyPassword=votre_mot_de_passe_cle
   keyAlias=frogazz
   storeFile=frogazz-upload-keystore.jks
   ```

---

## 📦 Étape 4 : Compiler le fichier officiel Google Play (`.aab`)

Exécutez la commande de compilation release (ou lancez notre script `build_playstore_aab.sh`) :

```bash
cd flutter_app
flutter build appbundle --release --obfuscate --split-debug-info=./build/app/outputs/symbols
```

- **Fichier généré** :  
  **`flutter_app/build/app/outputs/bundle/release/app-release.aab`**
- *C'est ce fichier unique (`.aab`) que vous devez envoyer sur la Google Play Console !*

---

## 📝 Étape 5 : Créer la fiche du store sur Google Play Console

Dans votre tableau de bord Google Play Console, cliquez sur **"Créer une application"** :
1. **Informations générales** :
   - **Nom de l'application** : `Frogazz Sport Analyse - Pronostics VIP`
   - **Description courte** : `Analyses sportives d'experts, combinés Côte 5, 10, 50 et stratégie Montante.`
   - **Description complète** :
     ```text
     🐸 Bienvenue sur Frogazz Sport Analyse, la plateforme professionnelle de pronostics sportifs !
     
     🏆 NOS OFFRES ET FONCTIONNALITÉS :
     • ⚡ COMBINÉS CÔTE 5 QUOTIDIENS : 2 à 4 matchs sélectionnés par nos algorithmes pour une cote cumulée autour de 5.00.
     • 👑 COMBINÉS CÔTE 10 & 50 : Analyses VIP exclusives pour maximiser vos gains.
     • 📈 STRATÉGIE MONTANTE : Gestion de bankroll pas-à-pas sur 7 jours.
     • 💳 PAIEMENT MOBILE SÉCURISÉ : Abonnez-vous facilement via Orange Money, Moov Money, Wave et Carte Bancaire (CinetPay / PayDunya).
     • 📲 NOTIFICATIONS PUSH : Soyez alerté instantanément dès qu'un pronostic est en ligne !
     ```
2. **Captures d'écran (Screenshots)** :
   - Ajoutez 3 à 5 captures d'écran de l'application mobile montrant la bannière Frogazz 🐸, la liste des combinés et la modale de détail.
3. **Lien de la Politique de Confidentialité** :
   - Collez l'URL de confidentialité de votre API en ligne :
     ```
     https://pronostics-api-server.onrender.com/api/v1/support/privacy
     ```
4. **Validation des contenus (Jeux d'argent / Sport)** :
   - Dans le questionnaire Google, précisez que l'application fournit des **analyses et conseils sportifs** et ne constitue pas une application de jeux de hasard en direct.

---

## 🚀 Étape 6 : Soumettre pour vérification !

- Téléversez le fichier **`app-release.aab`** et soumettez la version pour examen par l'équipe Google.
- **Délai habituel** : 2 à 5 jours ouvrés.  
  Dès la validation, **Frogazz Sport Analyse** sera téléchargeable dans le monde entier sur le Google Play Store !
