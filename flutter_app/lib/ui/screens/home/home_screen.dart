import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/prediction_provider.dart';
import '../../widgets/prediction_card.dart';

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, color: AppTheme.gold, size: 22),
            const SizedBox(width: 8),
            const Text('PRONOSTICS VIP'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.gold),
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
              // 1. BANNIÈRE MODERNE (STATUT ABONNEMENT OU CTA ESSAI GRATUIT)
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
                          style: TextStyle(color: AppTheme.grey),
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
                      style: const TextStyle(color: AppTheme.red),
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
    final isTrial = user?.hasFreeTrialCote5 ?? false;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVip
              ? [const Color(0xFFD4AF37), const Color(0xFF996515)]
              : [const Color(0xFF16161A), const Color(0xFF23232A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.15),
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
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isVip ? '👑 MEMBRE VIP ACTIF' : (isTrial ? '🎁 ESSAI GRATUIT 48H' : '🔒 NON ABONNÉ'),
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.shield_moon, color: AppTheme.gold),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isVip
                ? 'Accès Illimité à Nos Pronostics Experts'
                : 'Passez au Forfait VIP ou Montante',
            style: TextStyle(
              color: isVip ? Colors.black : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isVip
                ? 'Profitez des Côtes 5, 10, 50 et de nos analyses exclusives.'
                : 'Débloquez toutes les côtes et maximisez vos gains avec nos experts.',
            style: TextStyle(
              color: isVip ? Colors.black87 : AppTheme.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          if (!isVip)
            ElevatedButton(
              onPressed: () => context.push('/subscription-plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
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
          _buildStatItem('86%', 'Réussite', AppTheme.green),
          _buildDivider(),
          _buildStatItem('54.00', 'Cote Max', AppTheme.gold),
          _buildDivider(),
          _buildStatItem('15+', 'Pronos/Sem.', Colors.white),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppTheme.grey, fontSize: 11),
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

  // 3. TABS CATÉGORIES (MONTANTE, VIP, COTE 5, COTE 10, COTE 50)
  Widget _buildCategoryTabs(WidgetRef ref, String currentCategory) {
    final categories = [
      {'key': 'ALL', 'label': '🔥 TOUS'},
      {'key': 'MONTANTE', 'label': '📈 MONTANTE'},
      {'key': 'COTE_5', 'label': '⚡ CÔTE 5'},
      {'key': 'COTE_10', 'label': '👑 CÔTE 10'},
      {'key': 'COTE_50', 'label': '💎 CÔTE 50 (SEMAINE)'},
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
                color: isSelected ? AppTheme.gold : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.gold : AppTheme.darkBorder,
                ),
              ),
              child: Text(
                cat['label']!,
                style: TextStyle(
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
