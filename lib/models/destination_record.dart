import 'package:flutter/material.dart';
import 'price_info.dart';

/// Provenance is assigned by the repository boundary; IDs alone do not prove
/// that a record came from the database.
enum DestinationRecordSource { unknown, database, fallback }

/// Numeric validity is separate from whether the value has verified
/// provenance. A plausible number without explicit rating verification is
/// retained as data but is not presented as an available public rating.
enum DestinationRatingDataState { available, missing, invalid }

enum DestinationRatingVerification { verified, unverified, unknown }

class DestinationRecord {
  final String id;
  final String name;
  final String location;
  final double lat;
  final double lng;
  final String? categoryId;
  final String category;
  /// Parsed 0..5 value, retained even if provenance is not verified.
  final double? rating;
  final DestinationRatingDataState ratingDataState;
  final DestinationRatingVerification ratingVerification;
  final String? ratingSource;
  final DateTime? ratingRetrievedAt;
  final DateTime? ratingFreshUntil;
  final String status;
  final bool isVerified;
  final String? description;

  /// Raw amount from the row or sample fixture. It has no implied currency,
  /// pricing basis, or verification status.
  final Object? rawEntranceFee;
  final int averageStayMinutes;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? ownerName;
  final Map<String, String>? operatingHours; // {"open":"08:00","close":"17:00"}
  final DestinationRecordSource source;
  final bool hasUsableCoordinates;
  final bool hasUsableVisitDuration;

  const DestinationRecord({
    required this.id,
    required this.name,
    required this.location,
    required this.lat,
    required this.lng,
    this.categoryId,
    required this.category,
    required this.rating,
    this.ratingDataState = DestinationRatingDataState.available,
    this.ratingVerification = DestinationRatingVerification.unknown,
    this.ratingSource,
    this.ratingRetrievedAt,
    this.ratingFreshUntil,
    required this.status,
    required this.isVerified,
    this.description,
    this.rawEntranceFee,
    this.averageStayMinutes = 60,
    this.imageUrl,
    this.imageUrls = const [],
    this.ownerName,
    this.operatingHours,
    this.source = DestinationRecordSource.unknown,
    this.hasUsableCoordinates = false,
    this.hasUsableVisitDuration = false,
  });

  bool get isActive => status == 'active';
  bool get isMaintenance => status == 'maintenance';

  /// Visit hours for the MOGA planner (converts minutes → hours)
  double get visitHours => averageStayMinutes / 60.0;

  PriceInfo get entrancePrice => PriceInfo.fromRaw(rawEntranceFee);

  /// Only an explicitly verified, valid database rating is displayable as a
  /// public rating. Bundled fallback values and unverified values remain
  /// preserved in [rating] but are unavailable to rating consumers.
  double? get availableRating {
    if (source == DestinationRecordSource.fallback ||
        ratingDataState != DestinationRatingDataState.available ||
        ratingVerification != DestinationRatingVerification.verified) {
      return null;
    }
    return rating;
  }

  /// Display text does not infer currency, pricing basis, or free admission.
  String get formattedPrice => entrancePrice.displayLabel;

  /// Primary image URL with fallback
  String get primaryImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    if (imageUrls.isNotEmpty) return imageUrls.first;
    // Fallback placeholder by category
    return _fallbackImageForCategory(category);
  }

  /// Gallery URLs (excluding the primary if already included)
  List<String> get galleryUrls {
    if (imageUrls.length <= 1) return [];
    return imageUrls.sublist(1);
  }

  /// Category icon
  IconData get categoryIcon {
    switch (category) {
      case 'Beach':
        return Icons.beach_access_rounded;
      case 'Falls':
        return Icons.water_drop_rounded;
      case 'Mountain':
        return Icons.landscape_rounded;
      case 'Resort':
        return Icons.villa_rounded;
      case 'Island':
        return Icons.sailing_rounded;
      case 'Historical':
        return Icons.account_balance_rounded;
      case 'Hotel':
        return Icons.hotel_rounded;
      case 'Dive Site':
        return Icons.scuba_diving_rounded;
      case 'Forest':
        return Icons.park_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  factory DestinationRecord.fromJson(
    Map<String, dynamic> json, {
    DestinationRecordSource source = DestinationRecordSource.unknown,
  }) {
    final status =
        json['status'] as String? ??
        ((json['is_active'] as bool? ?? true) ? 'active' : 'inactive');

    // Parse image_urls from Postgres TEXT[] or JSON array
    List<String> parsedImageUrls = [];
    final rawUrls = json['image_urls'];
    if (rawUrls is List) {
      parsedImageUrls = rawUrls.map((e) => e.toString()).toList();
    }

    // Parse operating_hours from JSONB
    Map<String, String>? parsedHours;
    final rawHours = json['operating_hours'];
    if (rawHours is Map) {
      parsedHours = rawHours.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }

    final rawRating = json.containsKey('rating_average')
        ? json['rating_average']
        : json['rating'];
    final parsedRating = _tryFiniteDouble(rawRating);
    final validRating = parsedRating != null &&
        parsedRating >= 0 &&
        parsedRating <= 5;
    final ratingVerification = switch (json['rating_is_verified']) {
      true => DestinationRatingVerification.verified,
      false => DestinationRatingVerification.unverified,
      _ => DestinationRatingVerification.unknown,
    };

    int parseInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    final categoryId = _parseNullableUuid(json['category_id']);
    final rawLat = json['lat'] ?? json['latitude'];
    final rawLng = json['lng'] ?? json['longitude'];
    final parsedLat = _tryFiniteDouble(rawLat);
    final parsedLng = _tryFiniteDouble(rawLng);
    final rawVisitDuration = json['average_stay_minutes'];
    final visitDuration = _tryInteger(rawVisitDuration);

    return DestinationRecord(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unnamed Spot',
      location: json['location'] as String? ?? 'Samal Island',
      lat: _tryFiniteDouble(json['lat'] ?? json['latitude']) ?? 7.085,
      lng: _tryFiniteDouble(json['lng'] ?? json['longitude']) ?? 125.730,
      categoryId: categoryId,
      category: json['category'] as String? ?? 'Resort',
      rating: validRating ? parsedRating : null,
      ratingDataState: rawRating == null
          ? DestinationRatingDataState.missing
          : validRating
          ? DestinationRatingDataState.available
          : DestinationRatingDataState.invalid,
      ratingVerification: ratingVerification,
      ratingSource: _nonEmptyString(json['rating_source']),
      ratingRetrievedAt: _tryDateTime(json['rating_retrieved_at']),
      ratingFreshUntil: _tryDateTime(json['rating_fresh_until']),
      status: status,
      isVerified: json['is_verified'] as bool? ?? false,
      description: json['description'] as String?,
      rawEntranceFee: json['entrance_fee'],
      averageStayMinutes: parseInt(json['average_stay_minutes'], 60),
      imageUrl: json['image_url'] as String?,
      imageUrls: parsedImageUrls,
      ownerName: json['owner_name'] as String?,
      operatingHours: parsedHours,
      source: source,
      hasUsableCoordinates:
          parsedLat != null &&
          parsedLng != null &&
          parsedLat >= -90 &&
          parsedLat <= 90 &&
          parsedLng >= -180 &&
          parsedLng <= 180,
      hasUsableVisitDuration: visitDuration != null && visitDuration >= 0,
    );
  }

  static double? _tryFiniteDouble(Object? value) {
    final parsed = switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text),
      _ => null,
    };
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  static DateTime? _tryDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }

  static int? _tryInteger(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Serializes fields represented by this model using database column names.
  /// The original destination text category is kept alongside its nullable ID.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'lat': lat,
    'lng': lng,
    'category_id': categoryId,
    'category': category,
    'rating_average': rating,
    'status': status,
    'is_verified': isVerified,
    'description': description,
    'entrance_fee': rawEntranceFee,
    'average_stay_minutes': averageStayMinutes,
    'image_url': imageUrl,
    'image_urls': imageUrls,
    'operating_hours': operatingHours,
  };

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String? _parseNullableUuid(Object? value) {
    if (value == null) return null;
    if (value is String && _uuidPattern.hasMatch(value)) return value;
    throw const FormatException(
      'category_id must be null or a valid UUID string.',
    );
  }

  static String _fallbackImageForCategory(String category) {
    switch (category) {
      case 'Beach':
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80';
      case 'Falls':
        return 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=500&q=80';
      case 'Mountain':
        return 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=500&q=80';
      case 'Resort':
        return 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=500&q=80';
      case 'Island':
        return 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=500&q=80';
      case 'Historical':
        return 'https://images.unsplash.com/photo-1507163546605-a84d8ff1a3bb?auto=format&fit=crop&w=500&q=80';
      case 'Hotel':
        return 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=500&q=80';
      default:
        return 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=500&q=80';
    }
  }
}
