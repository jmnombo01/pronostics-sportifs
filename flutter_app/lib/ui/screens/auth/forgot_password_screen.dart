import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSubmitted = false;

  void _handleSubmit() async {
    if (_emailController.text.isNotEmpty) {
      final api = ref.read(apiServiceProvider);
      try {
        await api.forgotPassword(_emailController.text.trim());
        setState(() => _isSubmitted = true);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email introuvable dans notre base.'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RÉCUPÉRATION')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isSubmitted
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_read, color: AppTheme.gold, size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    'Email envoyé !',
                    style: TextStyle(inherit: true, fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Un lien de réinitialisation a été envoyé à votre adresse email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(inherit: true, color: AppTheme.grey),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('RETOUR À LA CONNEXION'),
                  )
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(inherit: true, fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.gold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Saisissez votre adresse email pour recevoir votre code de réinitialisation de mot de passe.',
                    style: TextStyle(inherit: true, color: AppTheme.grey),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Adresse email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'ENVOYER LE CODE',
                    onPressed: _handleSubmit,
                  ),
                ],
              ),
      ),
    );
  }
}
