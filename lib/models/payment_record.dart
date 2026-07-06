class PaymentRecord {
  final String id;
  final String? reservationId;
  final String establishmentId;
  final String touristId;
  final double amount;
  final String status;
  final String? paymentMethod;
  final String? paymongoReference;
  final DateTime? paidAt;
  final DateTime createdAt;
  final String? touristName;

  const PaymentRecord({
    required this.id,
    this.reservationId,
    required this.establishmentId,
    required this.touristId,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.paymongoReference,
    this.paidAt,
    required this.createdAt,
    this.touristName,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return PaymentRecord(
      id: json['id'] as String,
      reservationId: json['reservation_id'] as String?,
      establishmentId: json['establishment_id'] as String,
      touristId: json['tourist_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String?,
      paymongoReference: json['paymongo_reference'] as String?,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      touristName: profile?['display_name'] as String?,
    );
  }
}
