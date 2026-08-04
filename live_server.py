#!/usr/bin/env python3
import http.server
import socketserver
import json
import urllib.parse
import os
import time

PORT = 8000
DIRECTORY = "/home/user"

# Base de données en mémoire miroir du seeder Laravel 12 / MySQL
PREDICTIONS_DATA = [
    {
        "id": 1,
        "title": "⚡ COMBINÉ CÔTE 5 DU LUNDI (3 MATCHS)",
        "competition": "Europe - Combiné VIP",
        "country": "Europe",
        "championship": "Combiné Europe",
        "match_date": "2026-08-03",
        "match_time": "19:30",
        "home_team": "Real Madrid / PSG / Bayern",
        "away_team": "Séville / Lyon / Leipzig",
        "type": "COTE_5",
        "odds": 5.18,
        "confidence": 5,
        "status": "PENDING",
        "is_published": True,
        "selections": [
            {"match": "Real Madrid vs FC Séville", "championship": "La Liga", "time": "19:30", "tip": "Victoire Real Madrid (1)", "odds": 1.65},
            {"match": "PSG vs Olympique Lyonnais", "championship": "Ligue 1", "time": "20:45", "tip": "Les deux équipes marquent (BTTS - Oui)", "odds": 1.80},
            {"match": "Bayern Munich vs RB Leipzig", "championship": "Bundesliga", "time": "18:30", "tip": "Plus de 2.5 buts dans le match", "odds": 1.75}
        ],
        "analysis": "Combiné de 3 matchs sélectionnés par nos algorithmes : 1.65 × 1.80 × 1.75 = 5.18 de cote totale."
    },
    {
        "id": 2,
        "title": "⚡ COMBINÉ CÔTE 5 DU MARDI (3 MATCHS)",
        "competition": "Europe - Combiné VIP",
        "country": "Europe",
        "championship": "Combiné PL & Serie A",
        "match_date": "2026-08-04",
        "match_time": "16:30",
        "home_team": "Arsenal / Inter Milan / FC Porto",
        "away_team": "Chelsea / AC Milan / Benfica",
        "type": "COTE_5",
        "odds": 5.04,
        "confidence": 5,
        "status": "PENDING",
        "is_published": True,
        "selections": [
            {"match": "Arsenal vs Chelsea", "championship": "Premier League", "time": "16:30", "tip": "Victoire Arsenal & Plus de 1.5 buts", "odds": 1.80},
            {"match": "Inter Milan vs AC Milan", "championship": "Serie A", "time": "20:45", "tip": "Victoire Inter Milan (DNB 1)", "odds": 1.75},
            {"match": "FC Porto vs Benfica", "championship": "Liga Portugal", "time": "21:00", "tip": "Plus de 1.5 buts en 2e mi-temps", "odds": 1.60}
        ],
        "analysis": "Deuxième ticket Côte 5 de la semaine avec 3 sélections européennes à haute probabilité."
    },
    {
        "id": 3,
        "title": "👑 COMBINÉ CÔTE 10 - GRAND CHELEM (4 MATCHS)",
        "competition": "Europe - Combiné VIP",
        "country": "Europe",
        "championship": "Combiné Champions & Europa",
        "match_date": "2026-08-05",
        "match_time": "18:30",
        "home_team": "Man City / Juventus / Dortmund / Barça",
        "away_team": "Aston Villa / Naples / Francfort / Atl. Madrid",
        "type": "COTE_10",
        "odds": 10.45,
        "confidence": 4,
        "status": "PENDING",
        "is_published": True,
        "selections": [
            {"match": "Manchester City vs Aston Villa", "championship": "Premier League", "time": "18:30", "tip": "Man City & Haaland Buteur", "odds": 1.85},
            {"match": "Juventus vs Naples", "championship": "Serie A", "time": "20:45", "tip": "Moins de 3.5 buts", "odds": 1.70},
            {"match": "Borussia Dortmund vs Eintracht", "championship": "Bundesliga", "time": "17:30", "tip": "Victoire Dortmund (1)", "odds": 1.80},
            {"match": "FC Barcelone vs Atl. Madrid", "championship": "La Liga", "time": "21:00", "tip": "BTTS - Oui", "odds": 1.85}
        ],
        "analysis": "Combiné de 4 matchs pour atteindre notre cote 10 exclusive. Allouer 2% de bankroll."
    },
    {
        "id": 4,
        "title": "💎 MÉGA COMBINÉ SEMAINE VIP (6 MATCHS)",
        "competition": "Ligue des Champions",
        "country": "Europe",
        "championship": "Ligue des Champions",
        "match_date": "2026-08-06",
        "match_time": "21:00",
        "home_team": "Sélection 6 Équipes Européennes",
        "away_team": "Ligue des Champions",
        "type": "COTE_50",
        "odds": 54.20,
        "confidence": 4,
        "status": "PENDING",
        "is_published": True,
        "selections": [
            {"match": "6 Matchs UCL sélectionnés", "championship": "UCL", "time": "21:00", "tip": "Combiné 6 vainqueurs", "odds": 54.20}
        ],
        "analysis": "Notre combiné phare de la semaine réunit 6 sélections pour une cote de 54.20. Réservé aux VIP."
    },
    {
        "id": 5,
        "title": "📈 MONTANTE ÉTAPE 1 : Inter Milan vs AS Roma",
        "competition": "Serie A",
        "country": "Italie",
        "championship": "Serie A",
        "match_date": "2026-08-03",
        "match_time": "20:45",
        "home_team": "Inter Milan",
        "away_team": "AS Roma",
        "type": "MONTANTE",
        "odds": 1.85,
        "confidence": 5,
        "status": "PENDING",
        "is_published": True,
        "selections": [
            {"match": "Inter Milan vs AS Roma", "championship": "Serie A", "time": "20:45", "tip": "Victoire Inter Milan (DNB)", "odds": 1.85}
        ],
        "analysis": "Étape 1 de notre montante en 5 jours. Victoire de l'Inter Milan (remboursé si match nul)."
    }
]

TRANSACTIONS_LOG = []

class PronosticRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path

        # Redirections ergonomiques
        if path == "/":
            self.path = "/user_app/index.html"
            return super().do_GET()
        elif path == "/admin" or path == "/admin/":
            self.path = "/admin_dashboard/index.html"
            return super().do_GET()

        # Endpoints API REST v1
        if path == "/api/v1/predictions":
            query = urllib.parse.parse_qs(parsed_path.query)
            cat = query.get("type", [None])[0]
            data = PREDICTIONS_DATA
            if cat and cat != "ALL":
                data = [p for p in data if p["type"] == cat]
            self._send_json({"success": True, "data": data})
            return

        elif path == "/api/v1/admin/accounting/report":
            summary = {
                "success": True,
                "summary": {"total_transactions": 1020, "total_revenue_fcfa": 2040000},
                "breakdown_by_operator": [
                    {"operator": "Orange Money", "transactions_count": 420, "amount_fcfa": 840000},
                    {"operator": "MTN Mobile Money", "transactions_count": 310, "amount_fcfa": 620000},
                    {"operator": "Moov Money", "transactions_count": 180, "amount_fcfa": 360000},
                    {"operator": "Carte Bancaire", "transactions_count": 50, "amount_fcfa": 100000},
                ]
            }
            self._send_json(summary)
            return

        elif path == "/api/v1/paydunya/return":
            self._send_json({"success": True, "gateway": "PAYDUNYA", "message": "Paiement PayDunya confirmé avec succès ! Abonnement VIP débloqué."})
            return

        return super().do_GET()

    def do_POST(self):
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)

        payload = {}
        try:
            if post_data:
                payload = json.loads(post_data.decode('utf-8'))
        except Exception:
            pass

        # Webhook IPN PayDunya
        if path == "/api/v1/paydunya/ipn":
            tx_id = payload.get("custom_data", {}).get("transaction_id", "PD-LIVE-" + str(int(time.time())))
            TRANSACTIONS_LOG.append({
                "gateway": "PAYDUNYA",
                "transaction_id": tx_id,
                "amount": payload.get("invoice", {}).get("total_amount", 2000),
                "status": "ACCEPTED",
                "time": time.strftime("%Y-%m-%d %H:%M:%S")
            })
            print(f"[LIVE SERVER] IPN PayDunya validé : {tx_id} - 2000 FCFA")
            self._send_json({"code": "00", "message": "IPN PayDunya traité avec succès - Abonnement VIP activé !"})
            return

        # Webhook CinetPay
        elif path == "/api/v1/cinetpay/webhook":
            tx_id = payload.get("cpm_trans_id", "CP-LIVE-" + str(int(time.time())))
            TRANSACTIONS_LOG.append({
                "gateway": "CINETPAY",
                "transaction_id": tx_id,
                "amount": payload.get("cpm_amount", 2000),
                "status": "ACCEPTED",
                "time": time.strftime("%Y-%m-%d %H:%M:%S")
            })
            print(f"[LIVE SERVER] Webhook CinetPay validé : {tx_id}")
            self._send_json({"code": "00", "message": "Webhook CinetPay validé - Abonnement activé !"})
            return

        elif path == "/api/v1/subscriptions/subscribe":
            tx_id = "CP-20260803-" + str(int(time.time()) % 100000)
            self._send_json({
                "success": True,
                "transaction_id": tx_id,
                "amount": 2000,
                "currency": "XOF",
                "cinetpay_payment_url": f"https://secure.cinetpay.com/payment/simulate/{tx_id}"
            })
            return

        self._send_json({"success": False, "message": "Endpoint non trouvé"}, 404)

    def _send_json(self, data, status_code=200):
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

class ThreadedHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    allow_reuse_address = True

if __name__ == '__main__':
    with ThreadedHTTPServer(("0.0.0.0", PORT), PronosticRequestHandler) as httpd:
        print(f"🚀 Serveur LIVE de Pronostics et API démarré sur http://0.0.0.0:{PORT}")
        httpd.serve_forever()
