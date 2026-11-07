/// Planning preferences stored in `public.tourist_details`.
///
/// Database defaults are represented as stored values, not as evidence that a
/// tourist selected or confirmed them. The service currently treats profiles
/// as unconfirmed because the deployed contract has no confirmation field.
class TouristPlanningProfile {
  final String id;
  final String userId;
  final double budgetMin;
  final double budgetMax;
  final int availableHoursPerDay;
  final int tripDurationDays;
  final List<String>? preferredCategories;
  final double? currentLat;
  final double? currentLng;
  final String travelMode;
  final DateTime createdAt;
  final int? numberOfTourists;
  final int? childrenCount;
  final int? eldersCount;

  TouristPlanningProfile({
    required this.id,
    required this.userId,
    required this.budgetMin,
    required this.budgetMax,
    required this.availableHoursPerDay,
    required this.tripDurationDays,
    required List<String>? preferredCategories,
    required this.currentLat,
    required this.currentLng,
    required this.travelMode,
    required this.createdAt,
    required this.numberOfTourists,
    required this.childrenCount,
    required this.eldersCount,
  }) : preferredCategories = preferredCategories == null
           ? null
           : List.unmodifiable(preferredCategories);

  factory TouristPlanningProfile.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['preferred_categories'];
    List<String>? categories;
    if (rawCategories != null) {
      if (rawCategories is! List ||
          rawCategories.any((value) => value is! String)) {
        throw const FormatException(
          'preferred_categories must be null or an array of strings.',
        );
      }
      categories = rawCategories.cast<String>();
    }

    return TouristPlanningProfile(
      id: _requiredString(json, 'id'),
      userId: _requiredString(json, 'user_id'),
      budgetMin: _requiredDouble(json, 'budget_min'),
      budgetMax: _requiredDouble(json, 'budget_max'),
      availableHoursPerDay: _requiredInt(json, 'available_hours_per_day'),
      tripDurationDays: _requiredInt(json, 'trip_duration_days'),
      preferredCategories: categories,
      currentLat: _nullableDouble(json, 'current_lat'),
      currentLng: _nullableDouble(json, 'current_lng'),
      travelMode: _requiredString(json, 'travel_mode'),
      createdAt: _requiredDateTime(json, 'created_at'),
      numberOfTourists: _nullableInt(json, 'number_of_tourists'),
      childrenCount: _nullableInt(json, 'children_count'),
      eldersCount: _nullableInt(json, 'elders_count'),
    );
  }

  /// Serializes editable planning fields only. Identity and `created_at` are
  /// server-owned; the service supplies `user_id` from the auth session.
  Map<String, dynamic> toJson() => {
    'budget_min': budgetMin,
    'budget_max': budgetMax,
    'available_hours_per_day': availableHoursPerDay,
    'trip_duration_days': tripDurationDays,
    'preferred_categories': preferredCategories,
    'current_lat': currentLat,
    'current_lng': currentLng,
    'travel_mode': travelMode,
    'number_of_tourists': numberOfTourists,
    'children_count': childrenCount,
    'elders_count': eldersCount,
  };

  TouristPlanningProfileValidation validate(
    TouristPlanningProfileValidationPolicy policy,
  ) {
    final errors = <String, String>{};
    if (!budgetMin.isFinite || budgetMin < 0) {
      errors['budget_min'] = 'Budget minimum must be finite and nonnegative.';
    }
    if (!budgetMax.isFinite || budgetMax < 0 || budgetMax < budgetMin) {
      errors['budget_max'] =
          'Budget maximum must be finite, nonnegative, and at least the minimum.';
    }
    if (availableHoursPerDay <= 0 ||
        availableHoursPerDay > policy.maximumHoursPerDay) {
      errors['available_hours_per_day'] =
          'Available hours must be between 1 and ${policy.maximumHoursPerDay}.';
    }
    if (tripDurationDays <= 0 || tripDurationDays > policy.maximumTripDays) {
      errors['trip_duration_days'] =
          'Trip duration must be between 1 and ${policy.maximumTripDays} days.';
    }

    if (preferredCategories != null) {
      final categories = preferredCategories!;
      if (categories.toSet().length != categories.length) {
        errors['preferred_categories'] =
            'Categories must not contain duplicates.';
      }
      if (categories.any(
        (value) => !policy.validCategoryCodes.contains(value),
      )) {
        errors['preferred_categories'] =
            'Every category must match the approved category catalog.';
      }
    }

    if ((currentLat == null) != (currentLng == null)) {
      errors['coordinates'] =
          'Latitude and longitude must be supplied together.';
    }
    if (currentLat != null &&
        (!currentLat!.isFinite || currentLat! < -90 || currentLat! > 90)) {
      errors['current_lat'] = 'Latitude must be between -90 and 90.';
    }
    if (currentLng != null &&
        (!currentLng!.isFinite || currentLng! < -180 || currentLng! > 180)) {
      errors['current_lng'] = 'Longitude must be between -180 and 180.';
    }
    if (!policy.supportedTravelModes.contains(travelMode)) {
      errors['travel_mode'] = 'Travel mode is not in the approved set.';
    }

    if (numberOfTourists != null && numberOfTourists! <= 0) {
      errors['number_of_tourists'] =
          'Group size must be positive when supplied.';
    }
    if (childrenCount != null && childrenCount! < 0) {
      errors['children_count'] = 'Children count must be nonnegative.';
    }
    if (eldersCount != null && eldersCount! < 0) {
      errors['elders_count'] = 'Elders count must be nonnegative.';
    }
    if ((childrenCount != null || eldersCount != null) &&
        numberOfTourists == null) {
      errors['number_of_tourists'] =
          'Total group size is required when subgroup counts are supplied.';
    } else if (numberOfTourists != null &&
        ((childrenCount ?? 0) + (eldersCount ?? 0) > numberOfTourists!)) {
      errors['group_composition'] =
          'Children and elders cannot exceed the total group size.';
    }

    return TouristPlanningProfileValidation(errors);
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('$key must be a non-empty string.');
  }

  static double _requiredDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num && value.toDouble().isFinite) return value.toDouble();
    throw FormatException('$key must be a finite number.');
  }

  static double? _nullableDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is num && value.toDouble().isFinite) return value.toDouble();
    throw FormatException('$key must be null or a finite number.');
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw FormatException('$key must be an integer.');
  }

  static int? _nullableInt(Map<String, dynamic> json, String key) {
    if (json[key] == null) return null;
    return _requiredInt(json, key);
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('$key must be a valid timestamp.');
  }
}

/// Application limits and controlled vocabularies must be approved and
/// provided by the caller; this class deliberately defines no arbitrary values.
class TouristPlanningProfileValidationPolicy {
  final int maximumHoursPerDay;
  final int maximumTripDays;
  final Set<String> validCategoryCodes;
  final Set<String> supportedTravelModes;

  TouristPlanningProfileValidationPolicy({
    required this.maximumHoursPerDay,
    required this.maximumTripDays,
    required Set<String> validCategoryCodes,
    required Set<String> supportedTravelModes,
  }) : validCategoryCodes = Set.unmodifiable(validCategoryCodes),
       supportedTravelModes = Set.unmodifiable(supportedTravelModes) {
    if (maximumHoursPerDay <= 0 || maximumTripDays <= 0) {
      throw ArgumentError('Validation maxima must be positive.');
    }
    if (this.validCategoryCodes.isEmpty || this.supportedTravelModes.isEmpty) {
      throw ArgumentError(
        'Approved category codes and travel modes must be supplied.',
      );
    }
  }
}

class TouristPlanningProfileValidation {
  final Map<String, String> errors;

  TouristPlanningProfileValidation(Map<String, String> errors)
    : errors = Map.unmodifiable(errors);

  bool get isValid => errors.isEmpty;
}
