class UserModel {
  final int id;
  final String lastName;
  final String firstName;
  final String phone;
  final String email;
  final bool isAdmin;
  final String subscriptionStatus;
  final DateTime? subscriptionExpiresAt;
  final DateTime? freeTrialExpiresAt;
  final String? referralCode;
  final bool hasVip;
  final bool hasMontante;
  final bool hasFreeTrialCote5;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.phone,
    required this.email,
    required this.isAdmin,
    required this.subscriptionStatus,
    this.subscriptionExpiresAt,
    this.freeTrialExpiresAt,
    this.referralCode,
    required this.hasVip,
    required this.hasMontante,
    required this.hasFreeTrialCote5,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      lastName: json['last_name'] ?? '',
      firstName: json['first_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      isAdmin: json['is_admin'] ?? false,
      subscriptionStatus: json['subscription_status'] ?? 'NONE',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.tryParse(json['subscription_expires_at'])
          : null,
      freeTrialExpiresAt: json['free_trial_expires_at'] != null
          ? DateTime.tryParse(json['free_trial_expires_at'])
          : null,
      referralCode: json['referral_code'],
      hasVip: json['has_vip'] ?? false,
      hasMontante: json['has_montante'] ?? false,
      hasFreeTrialCote5: json['has_free_trial_cote_5'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
