class PaymentModel {
  final int id;
  final String transactionId;
  final int amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String paidAt;
  final String? planName;

  PaymentModel({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.paidAt,
    this.planName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? 0,
      transactionId: json['transaction_id'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'XOF',
      status: json['status'] ?? 'PENDING',
      paymentMethod: json['payment_method'] ?? 'MOBILE_MONEY',
      paidAt: json['paid_at'] ?? json['created_at'] ?? '',
      planName: json['plan'] != null ? json['plan']['name'] : null,
    );
  }
}
