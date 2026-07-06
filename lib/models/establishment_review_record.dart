class EstablishmentReviewRecord {
  final String id;
  final String establishmentId;
  final String touristId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? touristName;

  const EstablishmentReviewRecord({
    required this.id,
    required this.establishmentId,
    required this.touristId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.touristName,
  });

  factory EstablishmentReviewRecord.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return EstablishmentReviewRecord(
      id: json['id'] as String,
      establishmentId: json['establishment_id'] as String,
      touristId: json['tourist_id'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      touristName: profile?['display_name'] as String?,
    );
  }
}
