class LocationVerification {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String category;
  final String status;
  final DateTime createdAt;

  const LocationVerification({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  factory LocationVerification.fromJson(Map<String, dynamic> json) {
    return LocationVerification(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      category: json['category'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
