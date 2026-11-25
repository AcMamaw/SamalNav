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
  activityRelationshipsIncomplete,
  duplicateActivityIdentifiers,
  inactiveActivityRecords,
  staleActivityEvidence,
  invalidActivityEvidence,
  matched,
  noMatch,
}

class CarsInterestActivityMatchAssessment {
  final CarsInterestActivityMatchStatus status;
  final Set<String> matchedPreferenceIdentifiers;
  final Set<String> matchedActivityIdentifiers;
  final String? mappingSourceReference;
  final String? mappingVersion;
  final String? activitySourceReference;
  final DateTime? activityRetrievedAt;
  final DateTime? activityFreshUntil;

  CarsInterestActivityMatchAssessment({
    required this.status,
    Set<String> matchedPreferenceIdentifiers = const {},
    Set<String> matchedActivityIdentifiers = const {},
    this.mappingSourceReference,
    this.mappingVersion,
    this.activitySourceReference,
    this.activityRetrievedAt,
    this.activityFreshUntil,
  }) : matchedPreferenceIdentifiers = Set.unmodifiable(
         matchedPreferenceIdentifiers,
       ),
       matchedActivityIdentifiers = Set.unmodifiable(
         matchedActivityIdentifiers,
       );

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

/// Optional provenance contract for mappings that carry reviewable catalog
/// metadata. Mappings without this contract can be used in isolated tests,
/// but cannot represent a production-verified mapping source.
abstract interface class CarsInterestActivityCategoryMappingProvenance {
  String get sourceReference;
  String get version;
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
    bool activityRelationshipsComplete = true,
    bool hasDuplicateActivityIdentifiers = false,
    bool hasInactiveActivityRecords = false,
    bool hasInvalidActivityIdentifiers = false,
    String? activitySourceReference,
    DateTime? activityRetrievedAt,
    DateTime? activityFreshUntil,
    DateTime? assessedAt,
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

    final CarsInterestActivityCategoryMappingProvenance? mappingProvenance =
        categoryMapping is CarsInterestActivityCategoryMappingProvenance
        ? categoryMapping as CarsInterestActivityCategoryMappingProvenance
        : null;
    CarsInterestActivityMatchAssessment assessment(
      CarsInterestActivityMatchStatus status, {
      Set<String> matchedPreferences = const {},
      Set<String> matchedActivities = const {},
    }) => CarsInterestActivityMatchAssessment(
      status: status,
      matchedPreferenceIdentifiers: matchedPreferences,
      matchedActivityIdentifiers: matchedActivities,
      mappingSourceReference: mappingProvenance?.sourceReference,
      mappingVersion: mappingProvenance?.version,
      activitySourceReference: activitySourceReference,
      activityRetrievedAt: activityRetrievedAt,
      activityFreshUntil: activityFreshUntil,
    );

    final resolvedByPreference = <String, Set<String>>{};
    final resolvedActivityIdentifiers = <String>{};
    for (final preference in preferences) {
      final activityIdentifiers = categoryMapping
          .activityIdentifiersForPreference(preference);
      if (activityIdentifiers == null || activityIdentifiers.isEmpty) {
        return assessment(
          CarsInterestActivityMatchStatus.unsupportedPreferenceIdentifiers,
        );
      }
      resolvedByPreference[preference] = activityIdentifiers;
      resolvedActivityIdentifiers.addAll(activityIdentifiers);
    }

    final destinationActivities = destinationActivityIdentifiers;
    if (destinationActivities == null) {
      return assessment(
        CarsInterestActivityMatchStatus.activityCategoriesUnavailable,
      );
    }

    if (hasInvalidActivityIdentifiers) {
      return assessment(
        CarsInterestActivityMatchStatus.invalidActivityEvidence,
      );
    }
    if (hasDuplicateActivityIdentifiers) {
      return assessment(
        CarsInterestActivityMatchStatus.duplicateActivityIdentifiers,
      );
    }
    if (hasInactiveActivityRecords) {
      // The repository has no approved inactive-activity applicability rule.
      // Keep the evidence visible, but do not silently include or discard it.
      return assessment(
        CarsInterestActivityMatchStatus.inactiveActivityRecords,
      );
    }
    if (!activityRelationshipsComplete) {
      return assessment(
        CarsInterestActivityMatchStatus.activityRelationshipsIncomplete,
      );
    }
    if (activityRetrievedAt != null &&
        activityFreshUntil != null &&
        activityFreshUntil.isBefore(activityRetrievedAt)) {
      return assessment(
        CarsInterestActivityMatchStatus.invalidActivityEvidence,
      );
    }
    if (assessedAt != null) {
      if (activityRetrievedAt != null &&
          activityRetrievedAt.isAfter(assessedAt)) {
        return assessment(
          CarsInterestActivityMatchStatus.invalidActivityEvidence,
        );
      }
      if (activityFreshUntil != null &&
          !activityFreshUntil.isAfter(assessedAt)) {
        return assessment(
          CarsInterestActivityMatchStatus.staleActivityEvidence,
        );
      }
    }

    final overlap = resolvedActivityIdentifiers.intersection(
      destinationActivities,
    );
    if (overlap.isEmpty) {
      return assessment(CarsInterestActivityMatchStatus.noMatch);
    }

    final matchedPreferences = <String>{};
    for (final preference in preferences) {
      final mapped = resolvedByPreference[preference]!;
      if (mapped.any(overlap.contains)) matchedPreferences.add(preference);
    }
    return assessment(
      CarsInterestActivityMatchStatus.matched,
      matchedPreferences: matchedPreferences,
      matchedActivities: overlap,
    );
  }
}
