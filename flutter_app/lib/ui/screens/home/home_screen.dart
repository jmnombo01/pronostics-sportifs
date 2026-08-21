import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/prediction_provider.dart';
import '../../widgets/prediction_card.dart';
import '../../widgets/frog_mascot_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final predictionsAsync = ref.watch(predictionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🐸 ', style: TextStyle(inherit: true, fontSize: 20)),
              Text('FROGAZZ ', style: TextStyle(inherit: true, color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              Text('SPORT', style: TextStyle(inherit: true, color: AppTheme.frogGreen, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.frogGreen),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(predictionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BANNIÈRE MODERNE (STATUT ABONNEMENT OU MODE GRATUIT)
              _buildModernBanner(context, user),

              // 2. STATISTIQUES EN TEMPS RÉEL
              _buildStatsBar(),

              const SizedBox(height: 16),
              // 3. SECTIONS / CATÉGORIES (MONTANTE, VIP, CÔTE 5, CÔTE 10, CÔTE 50)
              _buildCategoryTabs(ref, selectedCategory),

              const SizedBox(height: 8),
              // 4. LISTE DES PRONOSTICS ACTUELS
              predictionsAsync.when(
                data: (predictions) {
                  if (predictions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Aucun pronostic disponible dans cette catégorie pour le moment.',
                          style: TextStyle(inherit: true, color: AppTheme.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: predictions.length,
                    itemBuilder: (context, index) {
                      return PredictionCardWidget(prediction: predictions[index]);
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'Erreur lors du chargement des pronostics: $err',
                      style: const TextStyle(inherit: true, color: AppTheme.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // 1. BANNIÈRE
  Widget _buildModernBanner(BuildContext context, user) {
    final isVip = user?.hasVip ?? false;
    final isMontante = user?.hasMontante ?? false;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVip
              ? [const Color(0xFF00E676), const Color(0xFF008D46)]
              : [const Color(0xFF102617), const Color(0xFF173822)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.frogGreen.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.frogGreen.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.frogGreen, width: 1),
                ),
                child: Text(
                  isVip ? '👑 MEMBRE VIP FROGAZZ ACTIF' : '🐸 MODE GRATUIT (3 MATCHS/JOUR)',
                  style: const TextStyle(inherit: true, 
                    color: AppTheme.frogGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Text('🐸', style: TextStyle(inherit: true, fontSize: 28)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isVip
                ? '🐸 Accès 100% Débloqué à Nos Pronostics'
                : '🐸 Combiné Gratuit 3 Matchs / Jour — Abonnez-vous pour Côtes 5, 10, 50',
            style: TextStyle(inherit: true, 
              color: isVip ? Colors.black : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isVip
                ? 'Profitez des Côtes 5, 10, 50 et de nos analyses d\'experts Frogazz.'
                : 'Débloquez toutes les côtes et sautez vers les gains avec nos analystes.',
            style: TextStyle(inherit: true, 
              color: isVip ? Colors.black87 : AppTheme.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          if (!isVip)
            ElevatedButton(
              onPressed: () => context.push('/subscription-plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.frogGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('VOIR LES ABONNEMENTS (2000 FCFA)'),
            ),
        ],
      ),
    );
  }

  // 2. BARRE DE STATISTIQUES
  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('86%', 'Réussite', AppTheme.frogGreen),
          _buildDivider(),
          _buildStatItem('54.00', 'Cote Max', Colors.white),
          _buildDivider(),
          _buildStatItem('🐸 15+', 'Pronos/Sem.', AppTheme.frogGreen),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(inherit: true, 
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(inherit: true, color: AppTheme.grey, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 28,
      width: 1,
      color: AppTheme.darkBorder,
    );
  }

  // 3. TABS CATÉGORIES FROGAZZ (GRATUIT 3 MATCHS, VIP COTE 5, 10, 50, MONTANTE)
  Widget _buildCategoryTabs(WidgetRef ref, String currentCategory) {
    final categories = [
      {'key': 'FREE_3_MATCHS', 'label': '🐸 GRATUIT (3 MATCHS)'},
      {'key': 'ALL', 'label': '🔥 TOUS'},
      {'key': 'COTE_5', 'label': '⚡ CÔTE 5 (VIP)'},
      {'key': 'COTE_10', 'label': '👑 CÔTE 10 (VIP)'},
      {'key': 'COTE_50', 'label': '💎 CÔTE 50 (VIP)'},
      {'key': 'MONTANTE', 'label': '📈 MONTANTE'},
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = currentCategory == cat['key'];

          return GestureDetector(
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = cat['key']!;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.frogGreen : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.frogGreen : AppTheme.darkBorder,
                ),
              ),
              child: Text(
                cat['label']!,
                style: TextStyle(inherit: true, 
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 4. BOTTOM NAV BAR
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppTheme.black,
      selectedItemColor: AppTheme.gold,
      unselectedItemColor: AppTheme.grey,
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            context.push('/subscription-plans');
            break;
          case 2:
            context.push('/history');
            break;
          case 3:
            context.push('/support');
            break;
          case 4:
            context.push('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.stars), label: 'Abonnement'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
        BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Support'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}
