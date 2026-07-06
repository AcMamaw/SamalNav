class DestinationRecord {
  final String id;
  final String name;
  final String location;
  final double lat;
  final double lng;
  final String category;
  final double rating;
  final String status;
  final bool isVerified;
  final String? description;
  final double entranceFee;
  final int averageStayMinutes;

  const DestinationRecord({
    required this.id,
    required this.name,
    required this.location,
    required this.lat,
    required this.lng,
    required this.category,
    required this.rating,
    required this.status,
    required this.isVerified,
    this.description,
    this.entranceFee = 0,
    this.averageStayMinutes = 60,
  });

  bool get isActive => status == 'active';

  factory DestinationRecord.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ??
        ((json['is_active'] as bool? ?? true) ? 'active' : 'inactive');
    return DestinationRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      category: json['category'] as String,
      rating: (json['rating_average'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0,
      status: status,
      isVerified: json['is_verified'] as bool? ?? false,
      description: json['description'] as String?,
      entranceFee: (json['entrance_fee'] as num?)?.toDouble() ?? 0,
      averageStayMinutes: json['average_stay_minutes'] as int? ?? 60,
    );
  }
}
