import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/cars_interest_activity_matcher.dart';

void main() {
  const preferenceBeach = 'preference-category-uuid-a';
  const preferenceCulture = 'preference-category-uuid-b';
  const activityBeach = 'activity-category-uuid-x';
  const activityCulture = 'activity-category-uuid-y';

  test('exact authoritative identifier mapping reports a match, not a score', () {
    final result = CarsInterestActivityMatcher(
      mapping: _Mapping({preferenceBeach: {activityBeach}}),
    ).assess(
      touristPreferenceIdentifiers: {preferenceBeach},
      destinationActivityIdentifiers: {activityBeach},
    );

    expect(result.status, CarsInterestActivityMatchStatus.matched);
    expect(result.matchedPreferenceIdentifiers, {preferenceBeach});
    expect(result.matchedActivityIdentifiers, {activityBeach});
    expect(result.criterionScore, isNull);
  });

  test('one preference can match multiple explicitly mapped activities', () {
    final result = CarsInterestActivityMatcher(
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
    final result = CarsInterestActivityMatcher(
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
      expect(result.status, CarsInterestActivityMatchStatus.noPreferenceSelected);
      expect(result.criterionScore, isNull);
    }
  });

  test('unknown preference identifier is unsupported, never a positive match', () {
    final result = CarsInterestActivityMatcher(
      mapping: _Mapping({preferenceBeach: {activityBeach}}),
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
  });

  test('missing destination activity categories are insufficient data', () {
    final result = CarsInterestActivityMatcher(
      mapping: _Mapping({preferenceBeach: {activityBeach}}),
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
    final unsupported = CarsInterestActivityMatcher(
      mapping: _Mapping(
        {preferenceBeach: {activityBeach}},
        isAuthoritative: false,
      ),
    ).assess(
      touristPreferenceIdentifiers: {preferenceBeach},
      destinationActivityIdentifiers: {activityBeach},
    );

    expect(unavailable.status, CarsInterestActivityMatchStatus.mappingUnavailable);
    expect(unsupported.status, CarsInterestActivityMatchStatus.mappingUnavailable);
    expect(unavailable.matchedActivityIdentifiers, isEmpty);
    expect(unsupported.matchedActivityIdentifiers, isEmpty);
    expect(unavailable.criterionScore, isNull);
    expect(unsupported.criterionScore, isNull);
  });

  test('known non-overlap is distinct from missing or unsupported mapping', () {
    final result = CarsInterestActivityMatcher(
      mapping: _Mapping({preferenceBeach: {activityBeach}}),
    ).assess(
      touristPreferenceIdentifiers: {preferenceBeach},
      destinationActivityIdentifiers: {activityCulture},
    );

    expect(result.status, CarsInterestActivityMatchStatus.noMatch);
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
