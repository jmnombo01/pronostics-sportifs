import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFIL UTILISATEUR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Aucun utilisateur connecté'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // AVATAR & NOM
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.gold, width: 2),
                    ),
                    child: const Icon(Icons.person, color: AppTheme.gold, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppTheme.grey, fontSize: 14),
                  ),
                  Text(
                    user.phone,
                    style: const TextStyle(color: AppTheme.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // BADGES D'ABONNEMENT
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STATUT D\'ABONNEMENT',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSubBadge('VIP (Côte 5/10/50)', user.hasVip),
                            _buildSubBadge('Montante', user.hasMontante),
                            _buildSubBadge('Essai 48h', user.hasFreeTrialCote5),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CODE DE PARRAINAGE
                  if (user.referralCode != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.green),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share, color: AppTheme.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'VOTRE CODE DE PARRAINAGE',
                                style: TextStyle(
                                  color: AppTheme.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            user.referralCode!,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Invitez vos amis et gagnez des jours d\'accès VIP offerts !',
                            style: TextStyle(color: AppTheme.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // PARAMÈTRES (THEME SOMBRE)
                  Card(
                    child: SwitchListTile(
                      title: const Text('Mode Sombre (Dark Mode)'),
                      subtitle: const Text('Interface Noir, Or et Vert'),
                      value: themeMode == ThemeMode.dark,
                      activeColor: AppTheme.gold,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.help_outline, color: AppTheme.gold),
                      title: const Text('Support & FAQ'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('/support'),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // BOUTON DECONNEXION
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout, color: AppTheme.red),
                      label: const Text(
                        'SE DÉCONNECTER',
                        style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.red.withOpacity(0.15),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSubBadge(String name, bool active) {
    return Column(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.cancel,
          color: active ? AppTheme.green : AppTheme.grey,
          size: 26,
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.grey,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
