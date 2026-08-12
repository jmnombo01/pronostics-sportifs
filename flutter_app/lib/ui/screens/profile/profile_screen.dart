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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🐸', style: TextStyle(inherit: true, fontSize: 48)),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun compte actif connecté',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        inherit: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Veuillez vous inscrire ou vous connecter pour accéder à votre profil et à vos abonnements VIP.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.grey, inherit: true),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('SE CONNECTER / S\'INSCRIRE'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // AVATAR & NOM
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: AppTheme.frogGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.frogGreen, width: 2),
                    ),
                    child: const Center(
                      child: Text('🐸', style: TextStyle(inherit: true, fontSize: 42)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        inherit: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppTheme.grey, fontSize: 14, inherit: true),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.phone,
                    style: const TextStyle(color: AppTheme.grey, fontSize: 13, inherit: true),
                  ),
                  const SizedBox(height: 24),

                  // BADGES D'ABONNEMENT
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                            color: AppTheme.frogGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            inherit: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildSubBadge('VIP (5/10/50)', user.hasVip)),
                            Expanded(child: _buildSubBadge('Montante', user.hasMontante)),
                            Expanded(child: _buildSubBadge('Essai 48h', user.hasFreeTrialCote5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // CODE DE PARRAINAGE
                  if (user.referralCode != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.frogGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.frogGreen),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🐸 ', style: TextStyle(inherit: true, fontSize: 18)),
                              Text(
                                'VOTRE CODE DE PARRAINAGE',
                                style: TextStyle(
                                  color: AppTheme.frogGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  inherit: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            user.referralCode!,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                              inherit: true,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Invitez vos amis et gagnez des jours d\'accès VIP offerts !',
                            style: TextStyle(color: AppTheme.grey, fontSize: 12, inherit: true),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),

                  // PARAMÈTRES (THEME SOMBRE UNIQUE)
                  Container(
                    key: const ValueKey('switch_dark_mode_box'),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.frogGreen),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: const Row(
                      children: [
                        Text('🐸 ', style: TextStyle(fontSize: 24, inherit: true)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thème Unique : Frogazz Dark Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                  inherit: true,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Interface Noir, Vert Grenouille & Blanc optimisée',
                                style: TextStyle(color: AppTheme.grey, fontSize: 12, inherit: true),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle, color: AppTheme.frogGreen, size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    key: const ValueKey('support_faq_box'),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: ListTile(
                      key: const ValueKey('support_faq_tile'),
                      leading: const Icon(Icons.help_outline, color: AppTheme.frogGreen),
                      title: const Text(
                        'Support & FAQ',
                        style: TextStyle(fontWeight: FontWeight.w600, inherit: true),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('/support'),
                    ),
                  ),
                  const SizedBox(height: 24),

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
                        style: TextStyle(
                          color: AppTheme.red,
                          fontWeight: FontWeight.bold,
                          inherit: true,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.red.withOpacity(0.15),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          active ? Icons.check_circle : Icons.cancel,
          color: active ? AppTheme.frogGreen : AppTheme.grey,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.grey,
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            inherit: true,
          ),
        ),
      ],
    );
  }
}
