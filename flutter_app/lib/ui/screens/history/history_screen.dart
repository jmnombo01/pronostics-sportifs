import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/prediction_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../widgets/prediction_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HISTORIQUE'),
          bottom: const TabBar(
            indicatorColor: AppTheme.gold,
            labelColor: AppTheme.gold,
            unselectedLabelColor: AppTheme.grey,
            tabs: [
              Tab(icon: Icon(Icons.history), text: 'Pronostics'),
              Tab(icon: Icon(Icons.payment), text: 'Paiements'),
              Tab(icon: Icon(Icons.card_membership), text: 'Abonnements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPredictionsHistoryTab(ref),
            _buildPaymentsHistoryTab(ref),
            _buildSubscriptionsHistoryTab(ref),
          ],
        ),
      ),
    );
  }

  // 1. HISTORIQUE PRONOSTICS
  Widget _buildPredictionsHistoryTab(WidgetRef ref) {
    final historyAsync = ref.watch(historyPredictionsProvider);

    return historyAsync.when(
      data: (predictions) {
        if (predictions.isEmpty) {
          return const Center(
            child: Text(
              'Aucun pronostic passé disponible.',
              style: TextStyle(inherit: true, color: AppTheme.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            return PredictionCardWidget(prediction: predictions[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      error: (err, _) => Center(child: Text('Erreur: $err', style: const TextStyle(inherit: true, color: AppTheme.red))),
    );
  }

  // 2. HISTORIQUE PAIEMENTS
  Widget _buildPaymentsHistoryTab(WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentHistoryProvider);

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return const Center(
            child: Text(
              'Aucun paiement enregistré pour l\'instant.',
              style: TextStyle(inherit: true, color: AppTheme.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final pay = payments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.monetization_on, color: AppTheme.gold, size: 36),
                title: Text(
                  '${pay.amount} ${pay.currency}',
                  style: const TextStyle(inherit: true, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  'ID: ${pay.transactionId}\nMéthode: ${pay.paymentMethod}',
                  style: const TextStyle(inherit: true, color: AppTheme.grey, fontSize: 12),
                ),
                trailing: _buildPayStatusBadge(pay.status),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      error: (err, _) => Center(child: Text('Erreur: $err', style: const TextStyle(inherit: true, color: AppTheme.red))),
    );
  }

  Widget _buildPayStatusBadge(String status) {
    Color col;
    String txt;
    switch (status) {
      case 'ACCEPTED':
        col = AppTheme.green;
        txt = 'CONFIRMÉ';
        break;
      case 'FAILED':
        col = AppTheme.red;
        txt = 'ÉCHOUÉ';
        break;
      default:
        col = AppTheme.gold;
        txt = 'EN ATTENTE';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: col.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        txt,
        style: TextStyle(inherit: true, color: col, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  // 3. HISTORIQUE ABONNEMENTS
  Widget _buildSubscriptionsHistoryTab(WidgetRef ref) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, color: AppTheme.gold, size: 54),
            SizedBox(height: 16),
            Text(
              'Gérez vos abonnements',
              style: TextStyle(inherit: true, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Vos abonnements actifs (VIP et Montante) ainsi que vos périodes d\'essai 48h apparaissent sur votre profil et sont pris en compte automatiquement en temps réel.',
              textAlign: TextAlign.center,
              style: TextStyle(inherit: true, color: AppTheme.grey),
            ),
          ],
        ),
      ),
    );
  }
}
