class ReviewRecord {
  final String id;
  final String touristId;
  final String destinationId;
  final String? establishmentId;
  final int stars;
  final String? reviewText;
  final DateTime createdAt;
  final String? touristName;

  const ReviewRecord({
    required this.id,
    required this.touristId,
    required this.destinationId,
    this.establishmentId,
    required this.stars,
    this.reviewText,
    required this.createdAt,
    this.touristName,
  });

  factory ReviewRecord.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ReviewRecord(
      id: json['id'] as String,
      touristId: json['tourist_id'] as String,
      destinationId: json['destination_id'] as String,
      establishmentId: json['establishment_id'] as String?,
      stars: json['stars'] as int,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      touristName: profile?['display_name'] as String?,
    );
  }
}
