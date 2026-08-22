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

class LigdiCashCheckoutState {
  final bool isLoading;
  final String? transactionId;
  final String? operator;
  final String? ussdCode;
  final String? errorMessage;
  final int? finalAmount;
  final String? appliedPromoCode;
  final bool paymentCompleted;

  LigdiCashCheckoutState({
    this.isLoading = false,
    this.transactionId,
    this.operator,
    this.ussdCode,
    this.errorMessage,
    this.finalAmount,
    this.appliedPromoCode,
    this.paymentCompleted = false,
  });

  LigdiCashCheckoutState copyWith({
    bool? isLoading,
    String? transactionId,
    String? operator,
    String? ussdCode,
    String? errorMessage,
    int? finalAmount,
    String? appliedPromoCode,
    bool? paymentCompleted,
  }) {
    return LigdiCashCheckoutState(
      isLoading: isLoading ?? this.isLoading,
      transactionId: transactionId ?? this.transactionId,
      operator: operator ?? this.operator,
      ussdCode: ussdCode ?? this.ussdCode,
      errorMessage: errorMessage,
      finalAmount: finalAmount ?? this.finalAmount,
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      paymentCompleted: paymentCompleted ?? this.paymentCompleted,
    );
  }
}

class LigdiCashCheckoutNotifier extends StateNotifier<LigdiCashCheckoutState> {
  final Ref ref;

  LigdiCashCheckoutNotifier(this.ref) : super(LigdiCashCheckoutState());

  Future<bool> applyPromoCode(String code, int basePrice) async {
    state = LigdiCashCheckoutState(isLoading: true);
    final api = ref.read(apiServiceProvider);
    try {
      final res = await api.checkPromoCode(code);
      if (res['success'] == true) {
        final discount = res['discount_percent'] as int;
        final newPrice = (basePrice * (100 - discount) / 100).round();
        state = LigdiCashCheckoutState(
          isLoading: false,
          finalAmount: newPrice,
          appliedPromoCode: code.toUpperCase(),
        );
        return true;
      }
    } catch (e) {
      state = LigdiCashCheckoutState(
        isLoading: false,
        errorMessage: 'Code promo invalide ou expiré.',
      );
    }
    return false;
  }

  /// Étape 1 : initier le paiement LigdiCash (retourne transaction_id + instructions USSD)
  Future<bool> initiatePayment({
    required String planCode,
    required String operator,
    required String phone,
    String? otp,
  }) async {
    state = LigdiCashCheckoutState(
      isLoading: true,
      appliedPromoCode: state.appliedPromoCode,
      finalAmount: state.finalAmount,
    );
    final api = ref.read(apiServiceProvider);

    try {
      final res = await api.subscribe(
        planCode: planCode,
        operator: operator,
        phone: phone,
        otp: otp,
        promoCode: state.appliedPromoCode,
      );

      if (res['success'] == true) {
        state = LigdiCashCheckoutState(
          isLoading: false,
          transactionId: res['transaction_id'],
          operator: res['operator'],
          ussdCode: res['ussd_code'],
          finalAmount: res['amount'],
          appliedPromoCode: state.appliedPromoCode,
        );
        return true;
      } else {
        state = LigdiCashCheckoutState(
          isLoading: false,
          errorMessage: res['message'] ?? 'Échec de l\'initialisation du paiement.',
          appliedPromoCode: state.appliedPromoCode,
        );
        return false;
      }
    } catch (e) {
      state = LigdiCashCheckoutState(
        isLoading: false,
        errorMessage: 'Erreur d\'initialisation du paiement LigdiCash.',
      );
    }
    return false;
  }

  /// Étape 2 : vérifier le statut du paiement (completed / pending / notcompleted)
  Future<String> checkPaymentStatus(String transactionId) async {
    final api = ref.read(apiServiceProvider);
    try {
      final res = await api.confirmLigdicash(transactionId);
      if (res['status'] == 'completed') {
        state = state.copyWith(paymentCompleted: true);
        return 'completed';
      }
      if (res['status'] == 'notcompleted') {
        state = state.copyWith(
          errorMessage: 'Paiement non abouti. Veuillez réessayer.',
        );
        return 'notcompleted';
      }
      return 'pending';
    } catch (e) {
      return 'pending';
    }
  }

  void reset() {
    state = LigdiCashCheckoutState();
  }
}

final ligdiCashCheckoutProvider =
    StateNotifierProvider<LigdiCashCheckoutNotifier, LigdiCashCheckoutState>((ref) {
  return LigdiCashCheckoutNotifier(ref);
});
