import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_plan_model.dart';
import '../models/payment_model.dart';
import 'auth_provider.dart';

// Forfaits d'abonnement disponibles
final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlanModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return await api.getPlans();
});

// Historique des paiements
final paymentHistoryProvider = FutureProvider<List<PaymentModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    return await api.getHistoryPayments();
  } catch (_) {
    return [];
  }
});

class CinetPayCheckoutState {
  final bool isLoading;
  final String? paymentUrl;
  final String? transactionId;
  final String? errorMessage;
  final int? finalAmount;
  final String? appliedPromoCode;

  CinetPayCheckoutState({
    this.isLoading = false,
    this.paymentUrl,
    this.transactionId,
    this.errorMessage,
    this.finalAmount,
    this.appliedPromoCode,
  });
}

class CinetPayCheckoutNotifier extends StateNotifier<CinetPayCheckoutState> {
  final Ref ref;

  CinetPayCheckoutNotifier(this.ref) : super(CinetPayCheckoutState());

  Future<bool> applyPromoCode(String code, int basePrice) async {
    state = CinetPayCheckoutState(isLoading: true);
    final api = ref.read(apiServiceProvider);
    try {
      final res = await api.checkPromoCode(code);
      if (res['success'] == true) {
        final discount = res['discount_percent'] as int;
        final newPrice = (basePrice * (100 - discount) / 100).round();
        state = CinetPayCheckoutState(
          isLoading: false,
          finalAmount: newPrice,
          appliedPromoCode: code.toUpperCase(),
        );
        return true;
      }
    } catch (e) {
      state = CinetPayCheckoutState(
        isLoading: false,
        errorMessage: 'Code promo invalide ou expiré.',
      );
    }
    return false;
  }

  Future<bool> initiatePayment({
    required String planCode,
    required String paymentMethod,
    required String phone,
  }) async {
    state = CinetPayCheckoutState(isLoading: true, appliedPromoCode: state.appliedPromoCode);
    final api = ref.read(apiServiceProvider);

    try {
      final res = await api.subscribe(
        planCode: planCode,
        paymentMethod: paymentMethod,
        phone: phone,
        promoCode: state.appliedPromoCode,
      );

      if (res['success'] == true) {
        state = CinetPayCheckoutState(
          isLoading: false,
          paymentUrl: res['cinetpay_payment_url'],
          transactionId: res['transaction_id'],
        );
        return true;
      }
    } catch (e) {
      state = CinetPayCheckoutState(
        isLoading: false,
        errorMessage: 'Erreur d\'initialisation CinetPay.',
      );
    }
    return false;
  }
}

final cinetPayCheckoutProvider =
    StateNotifierProvider<CinetPayCheckoutNotifier, CinetPayCheckoutState>((ref) {
  return CinetPayCheckoutNotifier(ref);
});
