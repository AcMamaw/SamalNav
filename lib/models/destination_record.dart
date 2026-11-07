import 'package:flutter/material.dart';
import 'price_info.dart';

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
  /// Raw amount from the row or sample fixture. It has no implied currency,
  /// pricing basis, or verification status.
  final Object? rawEntranceFee;
  final int averageStayMinutes;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? ownerName;
  final Map<String, String>? operatingHours; // {"open":"08:00","close":"17:00"}

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
    this.rawEntranceFee,
    this.averageStayMinutes = 60,
    this.imageUrl,
    this.imageUrls = const [],
    this.ownerName,
    this.operatingHours,
  });

  bool get isActive => status == 'active';
  bool get isMaintenance => status == 'maintenance';

  /// Visit hours for the MOGA planner (converts minutes → hours)
  double get visitHours => averageStayMinutes / 60.0;

  PriceInfo get entrancePrice => PriceInfo.fromRaw(rawEntranceFee);

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

  factory DestinationRecord.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ??
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
      parsedHours = rawHours.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    double parseDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    int parseInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    return DestinationRecord(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unnamed Spot',
      location: json['location'] as String? ?? 'Samal Island',
      lat: parseDouble(json['lat'] ?? json['latitude'], 7.085),
      lng: parseDouble(json['lng'] ?? json['longitude'], 125.730),
      category: json['category'] as String? ?? 'Resort',
      rating: parseDouble(json['rating_average'] ?? json['rating'], 4.5),
      status: status,
      isVerified: json['is_verified'] as bool? ?? false,
      description: json['description'] as String?,
      rawEntranceFee: json['entrance_fee'],
      averageStayMinutes: parseInt(json['average_stay_minutes'], 60),
      imageUrl: json['image_url'] as String?,
      imageUrls: parsedImageUrls,
      ownerName: json['owner_name'] as String?,
      operatingHours: parsedHours,
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
