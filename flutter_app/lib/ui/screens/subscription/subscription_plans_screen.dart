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
  String _operator = 'ORANGE';
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() async {
    if (_promoController.text.isNotEmpty) {
      final success = await ref
          .read(ligdiCashCheckoutProvider.notifier)
          .applyPromoCode(_promoController.text.trim(), 2000);
      if (mounted) {
        final state = ref.read(ligdiCashCheckoutProvider);
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

  Future<void> _initiatePayment() async {
    final success = await ref.read(ligdiCashCheckoutProvider.notifier).initiatePayment(
          planCode: _selectedPlanCode,
          operator: _operator,
          phone: _phoneController.text.trim(),
          otp: _operator == 'ORANGE' ? _otpController.text.trim() : null,
        );

    if (success && mounted) {
      _showWaitingModal();
    } else if (mounted) {
      final state = ref.read(ligdiCashCheckoutProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Erreur d\'initialisation du paiement'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }

  void _showWaitingModal() {
    final state = ref.read(ligdiCashCheckoutProvider);
    final txId = state.transactionId ?? '';
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _WaitingPaymentSheet(
          transactionId: txId,
          operator: state.operator ?? 'ORANGE',
          ussdCode: state.ussdCode,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(ligdiCashCheckoutProvider);
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
              'CODE PROMO OU PARRAINAGE',
              style: TextStyle(inherit: true, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _promoController,
                    label: '',
                    hint: 'Code promo (optionnel)',
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

            // 4. OPÉRATEUR MOBILE MONEY
            const Text(
              'OPÉRATEUR MOBILE MONEY',
              style: TextStyle(inherit: true, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildOperatorButton(
                  label: 'Orange Money',
                  icon: Icons.phone_android,
                  operator: 'ORANGE',
                ),
                const SizedBox(width: 12),
                _buildOperatorButton(
                  label: 'Moov Money',
                  icon: Icons.sim_card,
                  operator: 'MOOV',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Numéro de téléphone
            CustomTextField(
              controller: _phoneController,
              label: 'Numéro de téléphone',
              hint: 'Ex: +22670112233',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Instructions USSD + OTP pour Orange
            if (_operator == 'ORANGE') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.frogGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.frogGreen.withOpacity(0.6)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🐸 ', style: TextStyle(inherit: true, fontSize: 22)),
                    Expanded(
                      child: Text(
                        'Composez *144*4*6# sur votre téléphone Orange pour obtenir votre code OTP, puis saisissez-le ci-dessous.',
                        style: TextStyle(inherit: true, color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _otpController,
                label: 'Code OTP reçu',
                hint: '6 chiffres',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),

            // 5. BOUTON FINAL DE PAIEMENT
            CustomButton(
              text: 'PAYER $displayAmount FCFA AVEC LIGDICASH',
              isLoading: checkoutState.isLoading,
              icon: Icons.security,
              onPressed: _initiatePayment,
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Paiement sécurisé par LigdiCash • Orange Money & Moov Money',
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

  Widget _buildOperatorButton({
    required String label,
    required IconData icon,
    required String operator,
  }) {
    final isSelected = _operator == operator;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _operator = operator),
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

/// Modale d'attente + vérification du paiement LigdiCash
class _WaitingPaymentSheet extends ConsumerStatefulWidget {
  final String transactionId;
  final String operator;
  final String? ussdCode;

  const _WaitingPaymentSheet({
    required this.transactionId,
    required this.operator,
    this.ussdCode,
  });

  @override
  ConsumerState<_WaitingPaymentSheet> createState() => _WaitingPaymentSheetState();
}

class _WaitingPaymentSheetState extends ConsumerState<_WaitingPaymentSheet> {
  bool _checking = false;

  Future<void> _checkPayment() async {
    if (_checking) return;
    setState(() => _checking = true);
    final notifier = ref.read(ligdiCashCheckoutProvider.notifier);
    final status = await notifier.checkPaymentStatus(widget.transactionId);
    if (!mounted) return;
    setState(() => _checking = false);

    if (status == 'completed') {
      ref.read(authProvider.notifier).refreshProfile();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Abonnement activé ! Vous avez accès aux pronostics VIP.'),
          backgroundColor: AppTheme.green,
        ),
      );
      context.go('/');
    } else if (status == 'notcompleted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement non abouti. Veuillez réessayer.'),
          backgroundColor: AppTheme.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement en attente de validation. Réessayez dans quelques instants.'),
          backgroundColor: AppTheme.gold,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_top, color: AppTheme.gold, size: 64),
          const SizedBox(height: 16),
          const Text(
            'PAIEMENT LIGDICASH EN COURS',
            style: TextStyle(inherit: true, 
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.operator == 'ORANGE' && widget.ussdCode != null) ...[
            Text(
              'Composez ${widget.ussdCode} et validez sur votre téléphone Orange.',
              textAlign: TextAlign.center,
              style: const TextStyle(inherit: true, color: AppTheme.frogGreen, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const Text(
              'Validez la demande USSD reçue sur votre téléphone Moov.',
              textAlign: TextAlign.center,
              style: TextStyle(inherit: true, color: AppTheme.frogGreen, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            'Une fois le paiement validé, cliquez sur « Vérifier le paiement » pour activer votre abonnement.',
            textAlign: TextAlign.center,
            style: TextStyle(inherit: true, color: AppTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: _checking ? 'VÉRIFICATION...' : 'VÉRIFIER LE PAIEMENT',
            isLoading: _checking,
            onPressed: _checkPayment,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(inherit: true, color: AppTheme.grey),
            ),
          ),
        ],
      ),
    );
  }
}
