class ApiConstants {
  static const String baseUrl = 'https://pronostics-api-server.onrender.com/api/v1';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  static const String profile = '/auth/profile';
  static const String logout = '/auth/logout';

  // Predictions endpoints
  static const String predictions = '/predictions';
  static const String historyPredictions = '/history/predictions';
  static const String historyPayments = '/history/payments';
  static const String historySubscriptions = '/history/subscriptions';

  // Subscriptions & LigdiCash endpoints
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String subscribe = '/subscriptions/subscribe';
  static const String ligdicashConfirm = '/subscriptions/ligdicash/confirm';
  static const String mySubscriptions = '/subscriptions/my';
  static const String promoCheck = '/subscriptions/promo/check';

  // Support endpoints
  static const String faqs = '/support/faqs';
  static const String whatsapp = '/support/whatsapp';
  static const String terms = '/support/terms';
  static const String privacy = '/support/privacy';
  static const String referralInfo = '/referral/info';
}
