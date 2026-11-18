/// Result states for the CARS tourist-interest / destination-activity input.
///
/// This assesses identifier relationships only. It does not normalize the
/// assessment into a CARS score; the repository has no approved score formula
/// for this raw match result.
enum CarsInterestActivityMatchStatus {
  noPreferenceSelected,
  mappingUnavailable,
  unsupportedPreferenceIdentifiers,
  activityCategoriesUnavailable,
  matched,
  noMatch,
}

class CarsInterestActivityMatchAssessment {
  final CarsInterestActivityMatchStatus status;
  final Set<String> matchedPreferenceIdentifiers;
  final Set<String> matchedActivityIdentifiers;

  CarsInterestActivityMatchAssessment({
    required this.status,
    Set<String> matchedPreferenceIdentifiers = const {},
    Set<String> matchedActivityIdentifiers = const {},
  }) : matchedPreferenceIdentifiers = Set.unmodifiable(
         matchedPreferenceIdentifiers,
       ),
       matchedActivityIdentifiers = Set.unmodifiable(matchedActivityIdentifiers);

  /// No numeric criterion score is inferred from a categorical match.
  double? get criterionScore => null;
}

/// An explicitly supplied mapping from tourist preference identifiers to
/// destination activity identifiers. Callers must source this mapping from an
/// authoritative, reviewed catalog; display names are not mapping inputs.
abstract interface class CarsInterestActivityCategoryMapping {
  /// Whether this mapping is currently available and verified for use.
  bool get isAuthoritative;

  /// Returns null when the preference identifier is unsupported.
  Set<String>? activityIdentifiersForPreference(String preferenceIdentifier);
}

/// Strict assessment of CARS preference/activity identifier overlap.
///
/// No bundled mapping is provided because the repository contains no
/// authoritative link between `preferred_categories`, destination category
/// UUIDs, and activity identifiers. Without an authoritative mapping, selected
/// preferences remain insufficient data for this criterion.
class CarsInterestActivityMatcher {
  final CarsInterestActivityCategoryMapping? mapping;

  const CarsInterestActivityMatcher({this.mapping});

  CarsInterestActivityMatchAssessment assess({
    required Set<String>? touristPreferenceIdentifiers,
    required Set<String>? destinationActivityIdentifiers,
  }) {
    final preferences = touristPreferenceIdentifiers;
    if (preferences == null || preferences.isEmpty) {
      return CarsInterestActivityMatchAssessment(
        status: CarsInterestActivityMatchStatus.noPreferenceSelected,
      );
    }

    final categoryMapping = mapping;
    if (categoryMapping == null || !categoryMapping.isAuthoritative) {
      return CarsInterestActivityMatchAssessment(
        status: CarsInterestActivityMatchStatus.mappingUnavailable,
      );
    }

    final resolvedByPreference = <String, Set<String>>{};
    final resolvedActivityIdentifiers = <String>{};
    for (final preference in preferences) {
      final activityIdentifiers = categoryMapping
          .activityIdentifiersForPreference(preference);
      if (activityIdentifiers == null || activityIdentifiers.isEmpty) {
        return CarsInterestActivityMatchAssessment(
          status: CarsInterestActivityMatchStatus
              .unsupportedPreferenceIdentifiers,
        );
      }
      resolvedByPreference[preference] = activityIdentifiers;
      resolvedActivityIdentifiers.addAll(activityIdentifiers);
    }

    final destinationActivities = destinationActivityIdentifiers;
    if (destinationActivities == null) {
      return CarsInterestActivityMatchAssessment(
        status: CarsInterestActivityMatchStatus.activityCategoriesUnavailable,
      );
    }

    final overlap = resolvedActivityIdentifiers.intersection(
      destinationActivities,
    );
    if (overlap.isEmpty) {
      return CarsInterestActivityMatchAssessment(
        status: CarsInterestActivityMatchStatus.noMatch,
      );
    }

    final matchedPreferences = <String>{};
    for (final preference in preferences) {
      final mapped = resolvedByPreference[preference]!;
      if (mapped.any(overlap.contains)) matchedPreferences.add(preference);
    }
    return CarsInterestActivityMatchAssessment(
      status: CarsInterestActivityMatchStatus.matched,
      matchedPreferenceIdentifiers: matchedPreferences,
      matchedActivityIdentifiers: overlap,
    );
  }
}
