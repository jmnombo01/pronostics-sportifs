import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/user_model.dart';
import '../models/prediction_model.dart';
import '../models/subscription_plan_model.dart';
import '../models/payment_model.dart';
import '../models/faq_model.dart';

class ApiService {
  final DioClient _client;

  ApiService(this._client);

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> register({
    required String lastName,
    required String firstName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.register,
      data: {
        'last_name': lastName,
        'first_name': firstName,
        'phone': phone,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _client.dio.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
    return response.data;
  }

  Future<UserModel> getProfile() async {
    final response = await _client.dio.get(ApiConstants.profile);
    return UserModel.fromJson(response.data['user']);
  }

  Future<void> logout() async {
    try {
      await _client.dio.post(ApiConstants.logout);
    } catch (_) {}
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await _client.dio.post('/auth/fcm-token', data: {'fcm_token': token});
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // PREDICTIONS
  // ---------------------------------------------------------------------------
  Future<List<PredictionModel>> getPredictions({
    String? type,
    String? championship,
    String? team,
    String? matchDate,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    if (type != null && type.isNotEmpty && type != 'ALL') query['type'] = type;
    if (championship != null && championship.isNotEmpty) query['championship'] = championship;
    if (team != null && team.isNotEmpty) query['team'] = team;
    if (matchDate != null && matchDate.isNotEmpty) query['match_date'] = matchDate;
    if (status != null && status.isNotEmpty) query['status'] = status;

    final response = await _client.dio.get(
      ApiConstants.predictions,
      queryParameters: query,
    );

    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => PredictionModel.fromJson(e)).toList();
  }

  Future<PredictionModel> getPredictionDetail(int id) async {
    final response = await _client.dio.get('${ApiConstants.predictions}/$id');
    return PredictionModel.fromJson(response.data['data']);
  }

  Future<List<PredictionModel>> getHistoryPredictions() async {
    final response = await _client.dio.get(ApiConstants.historyPredictions);
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => PredictionModel.fromJson(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // SUBSCRIPTIONS & LIGDICASH
  // ---------------------------------------------------------------------------
  Future<List<SubscriptionPlanModel>> getPlans() async {
    final response = await _client.dio.get(ApiConstants.subscriptionPlans);
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => SubscriptionPlanModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> subscribe({
    required String planCode,
    required String operator,
    required String phone,
    String? otp,
    String? promoCode,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.subscribe,
      data: {
        'plan_code': planCode,
        'operator': operator,
        'phone': phone,
        if (otp != null && otp.isNotEmpty) 'otp': otp,
        if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> confirmLigdicash(String transactionId) async {
    final response = await _client.dio.post(
      ApiConstants.ligdicashConfirm,
      data: {'transaction_id': transactionId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> checkPromoCode(String code) async {
    final response = await _client.dio.post(
      ApiConstants.promoCheck,
      data: {'code': code},
    );
    return response.data;
  }

  // ---------------------------------------------------------------------------
  // HISTORIQUE PAIEMENTS & ABONNEMENTS
  // ---------------------------------------------------------------------------
  Future<List<PaymentModel>> getHistoryPayments() async {
    final response = await _client.dio.get(ApiConstants.historyPayments);
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => PaymentModel.fromJson(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // SUPPORT, FAQ, WHATSAPP, PARRAINAGE
  // ---------------------------------------------------------------------------
  Future<List<FaqModel>> getFaqs() async {
    final response = await _client.dio.get(ApiConstants.faqs);
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => FaqModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getWhatsAppInfo() async {
    final response = await _client.dio.get(ApiConstants.whatsapp);
    return response.data;
  }

  Future<Map<String, dynamic>> getTerms() async {
    final response = await _client.dio.get(ApiConstants.terms);
    return response.data;
  }

  Future<Map<String, dynamic>> getPrivacy() async {
    final response = await _client.dio.get(ApiConstants.privacy);
    return response.data;
  }

  Future<Map<String, dynamic>> getReferralInfo() async {
    final response = await _client.dio.get(ApiConstants.referralInfo);
    return response.data;
  }
}
