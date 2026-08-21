import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (success && mounted) {
        context.go('/');
      } else if (mounted) {
        final error = ref.read(authProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Erreur de connexion'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Couronne d'or
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.gold, width: 2),
                    ),
                    child: const Icon(Icons.workspace_premium, color: AppTheme.gold, size: 44),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'FROGAZZ SPORT ANALYSE',
                    style: TextStyle(inherit: true, 
                      color: AppTheme.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '🐸 Analyses VIP & Stratégie Montante',
                    style: TextStyle(inherit: true, color: AppTheme.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 36),

                  CustomTextField(
                    controller: _emailController,
                    label: 'Email ou Téléphone',
                    prefixIcon: const Icon(Icons.person_outline, color: AppTheme.gold),
                    validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.gold),
                    validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(inherit: true, color: AppTheme.gold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'SE CONNECTER',
                    isLoading: authState.isLoading,
                    onPressed: _handleLogin,
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pas encore de compte ? ', style: TextStyle(inherit: true, color: AppTheme.grey)),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: const Text(
                          'S\'inscrire (3 matchs gratuits/jour)',
                          style: TextStyle(inherit: true, 
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
