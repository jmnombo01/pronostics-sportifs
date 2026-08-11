import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/prediction_model.dart';

class PredictionCardWidget extends StatelessWidget {
  final PredictionModel prediction;
  final VoidCallback? onTap;

  const PredictionCardWidget({
    super.key,
    required this.prediction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        context.push('/prediction-detail/${prediction.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: prediction.isLocked
                ? AppTheme.red.withOpacity(0.4)
                : AppTheme.frogGreen.withOpacity(0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête : Championnat + Badge Catégorie
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Text('🐸 ', style: TextStyle(inherit: true, fontSize: 14)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  prediction.championship.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.frogGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    inherit: true,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                            if (prediction.matchesCount > 1) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.green, width: 0.8),
                                ),
                                child: Text(
                                  'COMBINÉ ${prediction.matchesCount} MATCHS',
                                  style: const TextStyle(inherit: true, 
                                    color: AppTheme.green,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                            _buildCategoryBadge(prediction.type),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Titre du Ticket / Match
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            prediction.title.isNotEmpty ? prediction.title : '${prediction.homeTeam} vs ${prediction.awayTeam}',
                            style: const TextStyle(inherit: true, 
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Badge Cote Cumulée
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.frogGreen, Color(0xFF00B248)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                prediction.odds.toStringAsFixed(2),
                                style: const TextStyle(inherit: true, 
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'COTE',
                                style: TextStyle(inherit: true, 
                                  color: Colors.black87,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Si c'est un Combiné de plusieurs matchs, afficher l'aperçu de chaque match !
                    if (prediction.matchesCount > 1 && prediction.selections.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: prediction.selections.take(3).map((sel) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.sports_soccer, size: 13, color: AppTheme.gold),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${sel.index}. ${sel.match}',
                                      style: const TextStyle(inherit: true, color: Colors.white70, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (sel.odds != null)
                                    Text(
                                      '(@${sel.odds!.toStringAsFixed(2)})',
                                      style: const TextStyle(inherit: true, color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Divider(color: AppTheme.darkBorder, height: 1),
                    const SizedBox(height: 12),

                    // Pied de carte : Date, Heure, Confiance et Statut
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: AppTheme.grey, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${prediction.matchDate} à ${prediction.matchTime}',
                              style: const TextStyle(inherit: true, color: AppTheme.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildConfidenceStars(prediction.confidence),
                            const SizedBox(width: 8),
                            _buildStatusBadge(prediction.status),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // OVERLAY DE VERROUILLAGE SI L'UTILISATEUR N'EST PAS ABONNÉ
              if (prediction.isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.90),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🐸🔒', style: TextStyle(inherit: true, fontSize: 40)),
                        const SizedBox(height: 8),
                        Text(
                          prediction.matchesCount > 1
                              ? '🔒 COMBINÉ CÔTE ${prediction.odds.toStringAsFixed(2)} (${prediction.matchesCount} MATCHS)'
                              : '🔒 PRONOSTIC RÉSERVÉ AUX ABONNÉS',
                          style: const TextStyle(inherit: true, 
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Abonnez-vous pour révéler les sélections Frogazz.',
                          style: TextStyle(inherit: true, color: AppTheme.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.push('/subscription-plans');
                          },
                          icon: const Icon(Icons.stars, size: 18),
                          label: const Text('Débloquer maintenant (2000 FCFA)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.frogGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String type) {
    Color bg;
    String label;
    switch (type) {
      case 'MONTANTE':
        bg = AppTheme.green;
        label = 'MONTANTE';
        break;
      case 'COTE_10':
        bg = AppTheme.gold;
        label = 'CÔTE 10';
        break;
      case 'COTE_50':
        bg = AppTheme.red;
        label = 'CÔTE 50 (SEMAINE)';
        break;
      case 'COTE_5':
      default:
        bg = Colors.blueAccent;
        label = 'CÔTE 5';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(inherit: true, 
          color: bg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildConfidenceStars(int count) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < count ? Icons.star : Icons.star_border,
          color: index < count ? AppTheme.frogGreen : AppTheme.grey,
          size: 14,
        );
      }),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'WON':
        color = AppTheme.green;
        text = 'GAGNÉ';
        break;
      case 'LOST':
        color = AppTheme.red;
        text = 'PERDU';
        break;
      case 'VOID':
        color = Colors.orange;
        text = 'REMBOURSÉ';
        break;
      case 'PENDING':
      default:
        color = AppTheme.gold;
        text = 'EN COURS';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(inherit: true, 
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
