class Establishment {
  final String id;
  final String ownerId;
  final String name;
  final String? address;
  final String category;
  final bool isVerified;

  const Establishment({
    required this.id,
    required this.ownerId,
    required this.name,
    this.address,
    required this.category,
    required this.isVerified,
  });

  factory Establishment.fromJson(Map<String, dynamic> json) {
    return Establishment(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      category: json['category'] as String? ?? 'Resort',
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}
