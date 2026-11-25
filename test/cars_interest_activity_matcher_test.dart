import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/cars_interest_activity_matcher.dart';

void main() {
  const preferenceBeach = 'preference-category-uuid-a';
  const preferenceCulture = 'preference-category-uuid-b';
  const activityBeach = 'activity-category-uuid-x';
  const activityCulture = 'activity-category-uuid-y';

  test(
    'exact authoritative identifier mapping reports a match, not a score',
    () {
      final result =
          CarsInterestActivityMatcher(
            mapping: _Mapping({
              preferenceBeach: {activityBeach},
            }),
          ).assess(
            touristPreferenceIdentifiers: {preferenceBeach},
            destinationActivityIdentifiers: {activityBeach},
          );

      expect(result.status, CarsInterestActivityMatchStatus.matched);
      expect(result.matchedPreferenceIdentifiers, {preferenceBeach});
      expect(result.matchedActivityIdentifiers, {activityBeach});
      expect(result.criterionScore, isNull);
    },
  );

  test('one preference can match multiple explicitly mapped activities', () {
    final result =
        CarsInterestActivityMatcher(
          mapping: _Mapping({
            preferenceBeach: {activityBeach, activityCulture},
          }),
        ).assess(
          touristPreferenceIdentifiers: {preferenceBeach},
          destinationActivityIdentifiers: {activityBeach, activityCulture},
        );

    expect(result.status, CarsInterestActivityMatchStatus.matched);
    expect(result.matchedActivityIdentifiers, {activityBeach, activityCulture});
    expect(result.criterionScore, isNull);
  });

  test('multiple preferences are assessed against their exact mapped IDs', () {
    final result =
        CarsInterestActivityMatcher(
          mapping: _Mapping({
            preferenceBeach: {activityBeach},
            preferenceCulture: {activityCulture},
          }),
        ).assess(
          touristPreferenceIdentifiers: {preferenceBeach, preferenceCulture},
          destinationActivityIdentifiers: {activityCulture},
        );

    expect(result.status, CarsInterestActivityMatchStatus.matched);
    expect(result.matchedPreferenceIdentifiers, {preferenceCulture});
    expect(result.matchedActivityIdentifiers, {activityCulture});
  });

  test('no selected preference is distinct from unavailable mapping', () {
    for (final preferences in <Set<String>?>[null, <String>{}]) {
      final result = const CarsInterestActivityMatcher().assess(
        touristPreferenceIdentifiers: preferences,
        destinationActivityIdentifiers: null,
      );
      expect(
        result.status,
        CarsInterestActivityMatchStatus.noPreferenceSelected,
      );
      expect(result.criterionScore, isNull);
    }
  });

  test(
    'unknown preference identifier is unsupported, never a positive match',
    () {
      final result =
          CarsInterestActivityMatcher(
            mapping: _Mapping({
              preferenceBeach: {activityBeach},
            }),
          ).assess(
            touristPreferenceIdentifiers: {'unknown-category-uuid'},
            destinationActivityIdentifiers: {activityBeach},
          );

      expect(
        result.status,
        CarsInterestActivityMatchStatus.unsupportedPreferenceIdentifiers,
      );
      expect(result.matchedActivityIdentifiers, isEmpty);
      expect(result.criterionScore, isNull);
    },
  );

  test('missing destination activity categories are insufficient data', () {
    final result =
        CarsInterestActivityMatcher(
          mapping: _Mapping({
            preferenceBeach: {activityBeach},
          }),
        ).assess(
          touristPreferenceIdentifiers: {preferenceBeach},
          destinationActivityIdentifiers: null,
        );

    expect(
      result.status,
      CarsInterestActivityMatchStatus.activityCategoriesUnavailable,
    );
    expect(result.criterionScore, isNull);
  });

  test('unavailable or unsupported mapping cannot produce a match', () {
    final unavailable = const CarsInterestActivityMatcher().assess(
      touristPreferenceIdentifiers: {preferenceBeach},
      destinationActivityIdentifiers: {activityBeach},
    );
    final unsupported =
        CarsInterestActivityMatcher(
          mapping: _Mapping({
            preferenceBeach: {activityBeach},
          }, isAuthoritative: false),
        ).assess(
          touristPreferenceIdentifiers: {preferenceBeach},
          destinationActivityIdentifiers: {activityBeach},
        );

    expect(
      unavailable.status,
      CarsInterestActivityMatchStatus.mappingUnavailable,
    );
    expect(
      unsupported.status,
      CarsInterestActivityMatchStatus.mappingUnavailable,
    );
    expect(unavailable.matchedActivityIdentifiers, isEmpty);
    expect(unsupported.matchedActivityIdentifiers, isEmpty);
    expect(unavailable.criterionScore, isNull);
    expect(unsupported.criterionScore, isNull);
  });

  test('known non-overlap is distinct from missing or unsupported mapping', () {
    final result =
        CarsInterestActivityMatcher(
          mapping: _Mapping({
            preferenceBeach: {activityBeach},
          }),
        ).assess(
          touristPreferenceIdentifiers: {preferenceBeach},
          destinationActivityIdentifiers: {activityCulture},
        );

    expect(result.status, CarsInterestActivityMatchStatus.noMatch);
    expect(result.criterionScore, isNull);
  });

  test('incomplete relationships cannot be reported as verified non-match', () {
    final result =
        CarsInterestActivityMatcher(
          mapping: _Mapping({
            preferenceBeach: {activityBeach},
          }),
        ).assess(
          touristPreferenceIdentifiers: {preferenceBeach},
          destinationActivityIdentifiers: {activityCulture},
          activityRelationshipsComplete: false,
        );

    expect(
      result.status,
      CarsInterestActivityMatchStatus.activityRelationshipsIncomplete,
    );
    expect(result.matchedActivityIdentifiers, isEmpty);
    expect(result.criterionScore, isNull);
  });

  test('duplicate, invalid, and inactive activity evidence is not matched', () {
    final matcher = CarsInterestActivityMatcher(
      mapping: _Mapping({
        preferenceBeach: {activityBeach},
      }),
    );
    CarsInterestActivityMatchAssessment assess({
      bool duplicate = false,
      bool invalid = false,
      bool inactive = false,
    }) => matcher.assess(
      touristPreferenceIdentifiers: {preferenceBeach},
      destinationActivityIdentifiers: {activityBeach},
      hasDuplicateActivityIdentifiers: duplicate,
      hasInvalidActivityIdentifiers: invalid,
      hasInactiveActivityRecords: inactive,
    );

    expect(
      assess(duplicate: true).status,
      CarsInterestActivityMatchStatus.duplicateActivityIdentifiers,
    );
    expect(
      assess(invalid: true).status,
      CarsInterestActivityMatchStatus.invalidActivityEvidence,
    );
    expect(
      assess(inactive: true).status,
      CarsInterestActivityMatchStatus.inactiveActivityRecords,
    );
    expect(assess(duplicate: true).criterionScore, isNull);
  });

  test('stale activity evidence is distinct and retains source metadata', () {
    final result =
        CarsInterestActivityMatcher(
          mapping: _Mapping({
            preferenceBeach: {activityBeach},
          }),
        ).assess(
          touristPreferenceIdentifiers: {preferenceBeach},
          destinationActivityIdentifiers: {activityBeach},
          activitySourceReference: 'synthetic activity catalog',
          activityRetrievedAt: DateTime.utc(2026, 1, 1),
          activityFreshUntil: DateTime.utc(2026, 1, 2),
          assessedAt: DateTime.utc(2026, 1, 3),
        );

    expect(
      result.status,
      CarsInterestActivityMatchStatus.staleActivityEvidence,
    );
    expect(result.activitySourceReference, 'synthetic activity catalog');
    expect(result.activityRetrievedAt, DateTime.utc(2026, 1, 1));
    expect(result.activityFreshUntil, DateTime.utc(2026, 1, 2));
    expect(result.criterionScore, isNull);
  });

  test('future retrieval timestamp is invalid activity evidence', () {
    final result =
        CarsInterestActivityMatcher(
          mapping: _Mapping({
            preferenceBeach: {activityBeach},
          }),
        ).assess(
          touristPreferenceIdentifiers: {preferenceBeach},
          destinationActivityIdentifiers: {activityBeach},
          activityRetrievedAt: DateTime.utc(2026, 1, 3),
          assessedAt: DateTime.utc(2026, 1, 2),
        );

    expect(
      result.status,
      CarsInterestActivityMatchStatus.invalidActivityEvidence,
    );
    expect(result.criterionScore, isNull);
  });

  test('mapping source and version are retained without affecting scores', () {
    final result =
        CarsInterestActivityMatcher(
          mapping: _VersionedMapping({
            preferenceBeach: {activityBeach},
          }),
        ).assess(
          touristPreferenceIdentifiers: {preferenceBeach},
          destinationActivityIdentifiers: {activityBeach},
          activitySourceReference: 'synthetic-test-catalog',
        );

    expect(result.status, CarsInterestActivityMatchStatus.matched);
    expect(result.mappingSourceReference, 'synthetic-mapping-catalog');
    expect(result.mappingVersion, 'fixture-v1');
    expect(result.activitySourceReference, 'synthetic-test-catalog');
    expect(result.criterionScore, isNull);
  });
}

class _Mapping implements CarsInterestActivityCategoryMapping {
  final Map<String, Set<String>> values;
  @override
  final bool isAuthoritative;

  _Mapping(this.values, {this.isAuthoritative = true});

  @override
  Set<String>? activityIdentifiersForPreference(String preferenceIdentifier) =>
      values[preferenceIdentifier];
}

class _VersionedMapping extends _Mapping
    implements CarsInterestActivityCategoryMappingProvenance {
  _VersionedMapping(super.values);

  @override
  String get sourceReference => 'synthetic-mapping-catalog';

  @override
  String get version => 'fixture-v1';
}
