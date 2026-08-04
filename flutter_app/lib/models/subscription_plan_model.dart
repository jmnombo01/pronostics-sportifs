class SubscriptionPlanModel {
  final int id;
  final String code;
  final String name;
  final int price;
  final int durationDays;
  final String durationLabel;
  final String description;
  final List<String> features;

  SubscriptionPlanModel({
    required this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.durationLabel,
    required this.description,
    required this.features,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'VIP',
      name: json['name'] ?? '',
      price: json['price'] ?? 2000,
      durationDays: json['duration_days'] ?? 30,
      durationLabel: json['duration_label'] ?? 'mois',
      description: json['description'] ?? '',
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
