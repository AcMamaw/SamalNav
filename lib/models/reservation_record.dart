class ReservationRecord {
  final String id;
  final String establishmentId;
  final String touristId;
  final String? destinationId;
  final String? serviceName;
  final int paxCount;
  final String reservationStatus;
  final DateTime eta;
  final DateTime createdAt;
  final String? touristName;

  const ReservationRecord({
    required this.id,
    required this.establishmentId,
    required this.touristId,
    this.destinationId,
    this.serviceName,
    required this.paxCount,
    required this.reservationStatus,
    required this.eta,
    required this.createdAt,
    this.touristName,
  });

  factory ReservationRecord.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ReservationRecord(
      id: json['id'] as String,
      establishmentId: json['establishment_id'] as String,
      touristId: json['tourist_id'] as String,
      destinationId: json['destination_id'] as String?,
      serviceName: json['service_name'] as String?,
      paxCount: json['pax_count'] as int? ?? 1,
      reservationStatus: json['reservation_status'] as String,
      eta: DateTime.parse(json['eta'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      touristName: profile?['display_name'] as String?,
    );
  }

  /// Minutes until ETA from now (for arrival alerts).
  int get etaMinutes => eta.difference(DateTime.now()).inMinutes.clamp(0, 999);
}
