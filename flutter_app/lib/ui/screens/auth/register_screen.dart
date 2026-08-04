import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authProvider.notifier).register(
            lastName: _lastNameController.text.trim(),
            firstName: _firstNameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            referralCode: _referralController.text.trim(),
          );

      if (success && mounted) {
        context.go('/');
      } else if (mounted) {
        final error = ref.read(authProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Erreur lors de l\'inscription'),
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
      appBar: AppBar(
        title: const Text('INSCRIPTION'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bandeau Offre Gratuit 48h
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.green),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.card_giftcard, color: AppTheme.green, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '🎁 CADEAU : 48 Heures d\'accès gratuit à la catégorie Côte 5 offertes dès l\'inscription !',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  controller: _lastNameController,
                  label: 'Nom',
                  validator: (val) => val == null || val.isEmpty ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _firstNameController,
                  label: 'Prénom',
                  validator: (val) => val == null || val.isEmpty ? 'Prénom requis' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Téléphone (ex: +22670112233)',
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? 'Téléphone requis' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Adresse email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val == null || val.isEmpty ? 'Email requis' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Mot de passe (min. 6 caractères)',
                  obscureText: true,
                  validator: (val) =>
                      (val == null || val.length < 6) ? 'Mot de passe trop court' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _referralController,
                  label: 'Code de parrainage (Optionnel)',
                  hint: 'Ex: SAWAD2026',
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'S\'INSCRIRE ET PROFITER DE L\'ESSAI',
                  isLoading: authState.isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
