import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/subscription_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  String _selectedPlanCode = 'VIP';
  String _paymentMethod = 'MOBILE_MONEY';
  final _phoneController = TextEditingController(text: '+22670112233');
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() async {
    if (_promoController.text.isNotEmpty) {
      final success = await ref
          .read(cinetPayCheckoutProvider.notifier)
          .applyPromoCode(_promoController.text.trim(), 2000);
      if (mounted) {
        final state = ref.read(cinetPayCheckoutProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Code promo appliqué ! Nouveau total : ${state.finalAmount} FCFA'
                  : (state.errorMessage ?? 'Code invalide'),
            ),
            backgroundColor: success ? AppTheme.green : AppTheme.red,
          ),
        );
      }
    }
  }

  void _initiateCinetPayPayment() async {
    final success = await ref.read(cinetPayCheckoutProvider.notifier).initiatePayment(
          planCode: _selectedPlanCode,
          paymentMethod: _paymentMethod,
          phone: _phoneController.text.trim(),
        );

    if (success && mounted) {
      final state = ref.read(cinetPayCheckoutProvider);
      _showPaymentSuccessModal(context, state.transactionId ?? 'CP-SIM-001');
    } else if (mounted) {
      final state = ref.read(cinetPayCheckoutProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Erreur d\'initialisation du paiement'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }

  void _showPaymentSuccessModal(BuildContext context, String txId) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'PAIEMENT CINETPAY CONFIRMÉ !',
                style: TextStyle(inherit: true, 
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transaction ID: $txId',
                style: const TextStyle(inherit: true, color: AppTheme.gold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'Votre abonnement a été activé automatiquement. Vous avez désormais accès à tous les pronostics réservés.',
                textAlign: TextAlign.center,
                style: TextStyle(inherit: true, color: AppTheme.grey),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'ACCÉDER AUX PRONOSTICS VIP',
                onPressed: () {
                  ref.read(authProvider.notifier).refreshProfile();
                  Navigator.of(ctx).pop();
                  context.go('/');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(cinetPayCheckoutProvider);
    final displayAmount = checkoutState.finalAmount ?? 2000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FORFAITS D\'ABONNEMENT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CHOISISSEZ VOTRE OFFRE',
              style: TextStyle(inherit: true, 
                color: AppTheme.gold,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Débloquez les pronostics Côte 5, 10, 50 ou Montante et maximisez vos gains.',
              style: TextStyle(inherit: true, color: AppTheme.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // 1. CARTE ABONNEMENT VIP
            _buildPlanCard(
              title: '👑 FORFAIT VIP',
              priceLabel: '2000 FCFA / MOIS',
              code: 'VIP',
              features: [
                'Côte 5 quotidienne garantie',
                'Côte 10 exclusive et analysée',
                'Pronostic Semaine (Côte min 50)',
                'Accès 30 jours renouvelable',
              ],
            ),
            const SizedBox(height: 16),

            // 2. CARTE ABONNEMENT MONTANTE
            _buildPlanCard(
              title: '📈 FORFAIT MONTANTE',
              priceLabel: '2000 FCFA / SEMAINE',
              code: 'MONTANTE',
              features: [
                'Pronostics Montante exclusifs',
                'Stratégie de gestion de mise pas-à-pas',
                'Statistiques de progression sur 7 jours',
              ],
            ),
            const SizedBox(height: 28),

            // 3. CODE PROMO
            const Text(
              'CODE PROMO OR PARRAINAGE',
              style: TextStyle(inherit: true, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _promoController,
                    label: '',
                    hint: 'Ex: WELCOME10 (-10%)',
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyPromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: const Text('APPLIQUER'),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 4. METHODE DE PAIEMENT CINETPAY
            const Text(
              'MOYEN DE PAIEMENT (CINETPAY)',
              style: TextStyle(inherit: true, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPaymentMethodButton(
                  label: 'Mobile Money',
                  icon: Icons.phone_android,
                  method: 'MOBILE_MONEY',
                ),
                const SizedBox(width: 12),
                _buildPaymentMethodButton(
                  label: 'Carte Bancaire',
                  icon: Icons.credit_card,
                  method: 'CREDIT_CARD',
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_paymentMethod == 'MOBILE_MONEY')
              CustomTextField(
                controller: _phoneController,
                label: 'Numéro de téléphone Mobile Money',
                hint: '+22670112233',
                keyboardType: TextInputType.phone,
              ),

            const SizedBox(height: 32),

            // 5. BOUTON FINAL DE PAIEMENT
            CustomButton(
              text: 'PAYER $displayAmount FCFA AVEC CINETPAY',
              isLoading: checkoutState.isLoading,
              icon: Icons.security,
              onPressed: _initiateCinetPayPayment,
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Paiement sécurisé par CinetPay • Orange Money, MTN, Moov, Airtel, Visa, Mastercard',
                style: TextStyle(inherit: true, color: AppTheme.grey, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String priceLabel,
    required String code,
    required List<String> features,
  }) {
    final isSelected = _selectedPlanCode == code;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanCode = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.gold : AppTheme.darkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      inherit: true,
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priceLabel,
                    style: const TextStyle(inherit: true, 
                      color: AppTheme.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppTheme.darkBorder, height: 1),
            const SizedBox(height: 14),
            ...features.map((feat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feat,
                        style: const TextStyle(inherit: true, color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodButton({
    required String label,
    required IconData icon,
    required String method,
  }) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.gold.withOpacity(0.2) : AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.gold : AppTheme.darkBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AppTheme.gold : Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(inherit: true, 
                  color: isSelected ? AppTheme.gold : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
