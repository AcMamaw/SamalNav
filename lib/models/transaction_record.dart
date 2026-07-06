class TransactionRecord {
  final String id;
  final String establishmentId;
  final String? bookingId;
  final String touristId;
  final double amount;
  final String status;
  final String? paymentMethod;
  final DateTime createdAt;
  final String? touristName;

  const TransactionRecord({
    required this.id,
    required this.establishmentId,
    this.bookingId,
    required this.touristId,
    required this.amount,
    required this.status,
    this.paymentMethod,
    required this.createdAt,
    this.touristName,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TransactionRecord(
      id: json['id'] as String,
      establishmentId: json['establishment_id'] as String,
      bookingId: json['booking_id'] as String?,
      touristId: json['tourist_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      touristName: profile?['display_name'] as String?,
    );
  }
}
