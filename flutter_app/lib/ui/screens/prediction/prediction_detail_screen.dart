import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/prediction_provider.dart';
import '../../widgets/custom_button.dart';

class PredictionDetailScreen extends ConsumerWidget {
  final int predictionId;

  const PredictionDetailScreen({super.key, required this.predictionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(predictionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DÉTAIL DU COMBINÉ / PRONOSTIC'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: predictionsAsync.when(
        data: (list) {
          final pred = list.firstWhere(
            (p) => p.id == predictionId,
            orElse: () => list.first,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : Ticket / Compétition
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (pred.matchesCount > 1) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.green),
                              ),
                              child: Text(
                                'TICKET COMBINÉ (${pred.matchesCount} MATCHS)',
                                style: const TextStyle(inherit: true, 
                                  color: AppTheme.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                          Text(
                            pred.championship.toUpperCase(),
                            style: const TextStyle(inherit: true, 
                              color: AppTheme.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        pred.title.isNotEmpty ? pred.title : '${pred.homeTeam} vs ${pred.awayTeam}',
                        style: const TextStyle(inherit: true, 
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${pred.matchDate} à ${pred.matchTime}',
                        style: const TextStyle(inherit: true, color: AppTheme.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBadge('COTE CUMULÉE', pred.odds.toStringAsFixed(2), AppTheme.green),
                          _buildBadge('CONFIANCE', '${pred.confidence}/5 ⭐', AppTheme.gold),
                          _buildBadge('STATUT', pred.status, Colors.blueAccent),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SI VERROUILLÉ -> AFFICHAGE CADRE 🔒
                if (pred.isLocked) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.red.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_outline, color: AppTheme.gold, size: 54),
                        const SizedBox(height: 16),
                        Text(
                          pred.matchesCount > 1
                              ? '🔒 COMBINÉ CÔTE ${pred.odds.toStringAsFixed(2)} (${pred.matchesCount} MATCHS) - RÉSERVÉ'
                              : '🔒 Réservé aux abonnés VIP / Montante',
                          style: const TextStyle(inherit: true, 
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          pred.matchesCount > 1
                              ? 'Pour débloquer la liste des ${pred.matchesCount} matchs de ce combiné, voir le pronostic précis de chaque match (1X2, buts, buteur) et notre conseil de mise, veuillez souscrire à un abonnement.'
                              : 'Pour accéder à l\'analyse détaillée du match, veuillez vous abonner.',
                          style: const TextStyle(inherit: true, color: AppTheme.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'DÉBLOQUER CE TICKET (2000 FCFA)',
                          onPressed: () {
                            context.push('/subscription-plans');
                          },
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // SI DÉVERROUILLÉ -> AFFICHAGE COMPLET DES MATCHS DU COMBINÉ !
                  if (pred.selections.isNotEmpty) ...[
                    Text(
                      '🎯 MATCHS DU TICKET COMBINÉ (${pred.selections.length} SÉLECTIONS)',
                      style: const TextStyle(inherit: true, 
                        color: AppTheme.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pred.selections.map((sel) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppTheme.gold.withOpacity(0.2),
                                      child: Text(
                                        '#${sel.index}',
                                        style: const TextStyle(inherit: true, color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sel.championship,
                                      style: const TextStyle(inherit: true, color: AppTheme.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Text(
                                  sel.matchTime,
                                  style: const TextStyle(inherit: true, color: AppTheme.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              sel.match,
                              style: const TextStyle(inherit: true, 
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.green.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.green),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.ads_click, color: AppTheme.green, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'PARI : ${sel.tip.toUpperCase()}',
                                        style: const TextStyle(inherit: true, 
                                          color: AppTheme.green,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (sel.odds != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.gold.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '@${sel.odds!.toStringAsFixed(2)}',
                                      style: const TextStyle(inherit: true, 
                                        color: AppTheme.gold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // ANALYSE ET STRATÉGIE DE MISE
                  const Text(
                    'ANALYSE & CONSEIL DE MISE',
                    style: TextStyle(inherit: true, 
                      color: AppTheme.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Text(
                      pred.analysis,
                      style: const TextStyle(inherit: true, 
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: AppTheme.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Conseil de gestion : Ne misez pas plus de 5% de votre bankroll sur ce combiné. Jouez responsable.',
                            style: TextStyle(inherit: true, color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildBadge(String label, String val, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(inherit: true, color: AppTheme.grey, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            val,
            style: TextStyle(inherit: true, 
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
