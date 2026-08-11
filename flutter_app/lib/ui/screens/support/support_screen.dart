import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/faq_model.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _launchWhatsApp() async {
    final url = Uri.parse('https://wa.me/22670000000?text=Bonjour%20Support%20Pronostics%20Sportifs');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqs = [
      FaqModel(
        id: 1,
        question: 'Comment fonctionne l\'essai gratuit de 48 heures ?',
        answer:
            'Dès votre inscription, votre compte accède gratuitement aux pronostics de la catégorie Côte 5 pendant 48 heures. Au-delà, un abonnement est requis.',
        category: 'ABONNEMENT',
      ),
      FaqModel(
        id: 2,
        question: 'Quelle est la différence entre l\'offre VIP et l\'offre Montante ?',
        answer:
            'L\'abonnement VIP (2000 FCFA/mois) donne accès aux pronostics Côte 5, Côte 10 et au Pronostic de la Semaine (Côte 50). L\'abonnement Montante (2000 FCFA/semaine) est réservé à la stratégie Montante.',
        category: 'ABONNEMENT',
      ),
      FaqModel(
        id: 3,
        question: 'Comment payer par Mobile Money via CinetPay ?',
        answer:
            'Sélectionnez votre forfait, choisissez "Mobile Money", saisissez votre numéro (Orange, MTN, Moov, Airtel) et validez la transaction dans l\'application CinetPay.',
        category: 'PAIEMENT',
      ),
      FaqModel(
        id: 4,
        question: 'À quelle heure sont publiés les pronostics chaque jour ?',
        answer:
            'Nos experts publient les pronostics quotidiennement entre 08h00 et 11h00 GMT. Vous recevez une notification push automatique !',
        category: 'PRONOSTICS',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SUPPORT & FAQ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BOUTON WHATSAPP DIRECT
            GestureDetector(
              onTap: _launchWhatsApp,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat, color: Colors.white, size: 36),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUPPORT WHATSAPP DIRECT',
                            style: TextStyle(inherit: true, 
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Discutez en direct avec notre équipe (7j/7, 08h - 22h GMT)',
                            style: TextStyle(inherit: true, color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // SECTION FAQ
            const Text(
              'QUESTIONS FRÉQUENTES (FAQ)',
              style: TextStyle(inherit: true, 
                color: AppTheme.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...faqs.map((faq) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  collapsedIconColor: AppTheme.gold,
                  iconColor: AppTheme.gold,
                  title: Text(
                    faq.question,
                    style: const TextStyle(inherit: true, 
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Text(
                        faq.answer,
                        style: const TextStyle(inherit: true, color: AppTheme.grey, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 28),

            // CGU & POLITIQUE DE CONFIDENTIALITÉ
            const Text(
              'INFORMATIONS LÉGALES',
              style: TextStyle(inherit: true, 
                color: AppTheme.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.gavel, color: AppTheme.gold),
                title: const Text('Conditions Générales d\'Utilisation (CGU)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showLegalModal(context, 'CGU',
                      '1. Objet : Les présentes conditions régissent l\'utilisation de l\'application Pronostics Sportifs.\n\n2. Essai Gratuit : 48h limitées à Côte 5.\n\n3. Responsabilité : Les pronostics sont fournis à titre indicatif et ne garantissent aucun gain absolu. Jouez de façon responsable.');
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip, color: AppTheme.green),
                title: const Text('Politique de Confidentialité'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showLegalModal(context, 'Politique de Confidentialité',
                      '1. Collecte : Nous collectons uniquement les données utiles à l\'activation de votre compte.\n\n2. Sécurité : Vos données et paiements CinetPay sont 100% sécurisés et chiffrés.');
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLegalModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(title, style: const TextStyle(inherit: true, color: AppTheme.gold)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(inherit: true, color: Colors.white70)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('FERMER', style: TextStyle(inherit: true, color: AppTheme.gold)),
          ),
        ],
      ),
    );
  }
}
