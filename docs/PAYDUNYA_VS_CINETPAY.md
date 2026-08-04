# 💳 PAYDUNYA VS CINETPAY : COMPARATIF & ARCHITECTURE MULTI-PASSERELLES

**Oui ! PayDunya est une excellente alternative et un complément idéal à CinetPay pour encaisser en Mobile Money et par Carte Bancaire en Afrique de l'Ouest et Centrale.**

Dans notre architecture Laravel 12, j'ai implémenté **les deux passerelles nativement** (`CinetPayService.php` et `PayDunyaService.php`). Vous pouvez utiliser **l'une ou l'autre**, ou même **les deux en mode redondance (Fallback)** afin de garantir **0% d'échec de paiement** !

---

## 📊 1. Comparatif Stratégique (Burkina Faso & UEMOA)

| Critère | **CinetPay** | **PayDunya** |
| :--- | :--- | :--- |
| **Implantation forte** | Côte d'Ivoire, Burkina Faso, Cameroun, Togo, Sénégal, Mali | Sénégal, Côte d'Ivoire, Bénin, Burkina Faso, Togo, Mali |
| **Opérateurs supportés (Burkina Faso)** | **Orange Money, Moov Money**, Airtel, Telecel, Cartes CB (Visa/Mastercard) | **Orange Money, Moov Money**, Free Money, **Wave** (Sénégal/RCI), Cartes CB |
| **Support de WAVE** | Via intégrations partenaires / en cours | **Excellent support natif de Wave** (très apprécié des utilisateurs) |
| **Type d'intégration** | `API_KEY` + `SITE_ID` + Webhook de statut HMAC (`checkPayStatus`) | `MasterKey` + `PrivateKey` + `Token` + **IPN (Instant Payment Notification)** SHA512 |
| **Frais moyens (Mobile Money)** | ~2.5% à 3.5% selon l'opérateur et le volume | ~2.0% à 3.0% selon l'opérateur et le pays |
| **Délais de virement / versement** | T+1 à T+3 (vers Mobile Money ou compte bancaire) | T+1 à T+2 (vers Mobile Money ou compte bancaire) |

---

## 🚀 2. Comment utiliser PayDunya dans l'API Laravel 12 ?

### A. Fichier de Configuration (`backend/config/paydunya.php`)
Dans votre fichier `backend/.env`, ajoutez les variables PayDunya :
```env
# =====================================================================
# CONFIGURATION PAYDUNYA (ALTERNATIVE OU MULTI-PASSERELLES)
# =====================================================================
PAYDUNYA_MASTER_KEY="votre_master_key"
PAYDUNYA_PRIVATE_KEY="votre_private_key_live"
PAYDUNYA_TOKEN="votre_token"
PAYDUNYA_MODE="live" # ou "test"
PAYDUNYA_IPN_URL="https://api.pronostics-sportifs.pro/api/v1/paydunya/ipn"
PAYDUNYA_RETURN_URL="https://api.pronostics-sportifs.pro/api/v1/paydunya/return"
PAYDUNYA_CANCEL_URL="https://api.pronostics-sportifs.pro/api/v1/paydunya/cancel"
```

### B. Architecture du Code Laravel 12 (Service & Webhook IPN)
1. **`PayDunyaService@initiatePayment`** : Génère une facture Checkout Invoice API v1 avec les coordonnées de l'application de pronostics et renvoie l'URL de paiement officielle (ou simulée en mode démo).
2. **`PayDunyaWebhookController@ipn`** (`POST /api/v1/paydunya/ipn`) : Intercepte la notification asynchrone émise par PayDunya dès que le client valide son code PIN sur son mobile, vérifie l'authenticité et **active automatiquement l'abonnement VIP ou Montante de l'utilisateur !**

---

## 💡 3. Notre Recommandation : Le Mode "Fallback / Redondance"

Pour maximiser votre taux de conversion dans l'application Flutter :
- Proposez **CinetPay en passerelle par défaut** pour les utilisateurs au Burkina Faso / Côte d'Ivoire.
- Si le réseau Orange Money ou MTN rencontre une maintenance temporaire sur CinetPay, **proposez automatiquement l'option "Payer via PayDunya (Orange Money / Wave / CB)"**.
- L'utilisateur aura ainsi **toujours une option fonctionnelle** pour s'abonner à votre offre VIP (2000 FCFA/mois) !
