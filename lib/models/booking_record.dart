class BookingRecord {
  final String id;
  final String establishmentId;
  final String touristId;
  final String serviceName;
  final int guestCount;
  final String status;
  final DateTime scheduledDate;
  final int? etaMinutes;
  final DateTime createdAt;
  final String? touristName;

  const BookingRecord({
    required this.id,
    required this.establishmentId,
    required this.touristId,
    required this.serviceName,
    required this.guestCount,
    required this.status,
    required this.scheduledDate,
    this.etaMinutes,
    required this.createdAt,
    this.touristName,
  });

  factory BookingRecord.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return BookingRecord(
      id: json['id'] as String,
      establishmentId: json['establishment_id'] as String,
      touristId: json['tourist_id'] as String,
      serviceName: json['service_name'] as String,
      guestCount: json['guest_count'] as int? ?? 1,
      status: json['status'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      etaMinutes: json['eta_minutes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      touristName: profile?['display_name'] as String?,
    );
  }
}
