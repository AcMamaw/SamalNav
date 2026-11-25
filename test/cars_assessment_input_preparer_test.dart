import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/cars_assessment_input_preparer.dart';
import 'package:samal_nav/algorithms/cars_budget_assessment.dart';
import 'package:samal_nav/algorithms/cars_engine.dart';
import 'package:samal_nav/algorithms/cars_interest_activity_matcher.dart';
import 'package:samal_nav/algorithms/cars_travel_assessment.dart';
import 'package:samal_nav/models/cars_models.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/services/open_weather_map_service.dart';

final _now = DateTime.utc(2026, 11, 18, 4);

DestinationRecord destination({
  Object? rating = 4.2,
  bool includeRating = true,
  bool verified = true,
  String? source = 'official rating source',
  bool includeTimestamps = true,
  DateTime? retrievedAt,
  DateTime? freshUntil,
  DestinationRecordSource recordSource = DestinationRecordSource.database,
}) {
  final retrieval = retrievedAt ?? DateTime.utc(2026, 11, 17);
  final freshness = freshUntil ?? DateTime.utc(2026, 11, 19);
  final row = <String, dynamic>{
    'id': 'destination-1',
    'name': 'Test destination',
    'status': 'active',
    if (includeRating) 'rating_average': rating,
    'rating_is_verified': verified,
    'rating_source': source,
    if (includeTimestamps) 'rating_retrieved_at': retrieval.toIso8601String(),
    if (includeTimestamps) 'rating_fresh_until': freshness.toIso8601String(),
  };
  return DestinationRecord.fromJson(row, source: recordSource);
}

WeatherForecastResult weather(WeatherForecastCoverage coverage) =>
    WeatherForecastResult(
      requestedLocation: const WeatherLocation(latitude: 10, longitude: 10),
      providerLatitude: 10,
      providerLongitude: 10,
      providerLocationName: 'Test location',
      providerCountryCode: 'PH',
      providerTimezoneOffsetSeconds: 28800,
      requestedStartDate: DateTime.utc(2026, 11, 18),
      requestedEndDate: DateTime.utc(2026, 11, 18),
      units: WeatherUnits.metric,
      retrievedAt: _now,
      points: const [],
      coverage: coverage,
      uncoveredDates: const [],
    );

CarsBudgetAssessment budget(
  BudgetAssessmentStatus status,
) => CarsBudgetAssessment(
  status: status,
  currency: status == BudgetAssessmentStatus.insufficientData ? null : 'PHP',
  knownSubtotal: status == BudgetAssessmentStatus.insufficientData ? null : 500,
  totalCost: status == BudgetAssessmentStatus.insufficientData ? null : 500,
  effectiveBudgetMaximum: status == BudgetAssessmentStatus.insufficientData
      ? null
      : 1000,
  groupSize: 1,
  adults: 1,
  children: 0,
  elders: 0,
  missingInformation: status == BudgetAssessmentStatus.insufficientData
      ? const ['Cost evidence expired.']
      : const [],
  costBreakdown: const {},
);

CarsTravelAssessment travel({bool stale = false}) {
  final leg = TravelLegAssessment(
    fromDestinationId: null,
    toDestinationId: 'destination-1',
    kind: TravelLegKind.originToFirstStop,
    straightLineKm: 9,
    routeDistanceKm: stale ? null : 12,
    estimatedTravelMinutes: stale ? null : 25,
    state: stale ? TravelEstimateState.stale : TravelEstimateState.available,
    explanation: stale ? 'Stale route.' : 'Fresh route.',
    source: 'test router',
    retrievedAt: _now,
  );
  return CarsTravelAssessment(
    days: [
      TravelDayAssessment(
        dayNumber: 1,
        itineraryDate: DateTime(2026, 11, 18),
        availableMinutes: 240,
        totalStraightLineKm: 9,
        totalRouteDistanceKm: stale ? null : 12,
        totalEstimatedTravelMinutes: stale ? null : 25,
        timeCompatibility: stale
            ? AvailableTimeCompatibility.unknown
            : AvailableTimeCompatibility.withinAvailableTime,
        legs: [leg],
        limitations: const [],
      ),
    ],
    limitations: const [],
  );
}

CarsInterestActivityMatchAssessment matchedInterest() =>
    CarsInterestActivityMatchAssessment(
      status: CarsInterestActivityMatchStatus.matched,
      matchedPreferenceIdentifiers: const {'interest-id'},
      matchedActivityIdentifiers: const {'activity-id'},
    );

CarsAssessmentPreparationInput completeInput({
  DestinationRecord? record,
  WeatherForecastCoverage weatherCoverage = WeatherForecastCoverage.available,
  CarsBudgetAssessment? budgetAssessment,
  CarsTravelAssessment? travelAssessment,
  CarsInterestActivityMatchAssessment? interest,
  bool preferencesConfirmed = true,
}) => CarsAssessmentPreparationInput(
  destination: record ?? destination(),
  interestActivityMatch: interest ?? matchedInterest(),
  preferencesConfirmed: preferencesConfirmed,
  weather: weather(weatherCoverage),
  budget: budgetAssessment ?? budget(BudgetAssessmentStatus.withinBudget),
  travel: travelAssessment ?? travel(),
  assessedAt: _now,
);

CarsPreparedAssessmentInputs prepare(
  CarsAssessmentPreparationInput input, {
  CarsApprovedCriterionScoringPolicy? policy,
}) => const CarsCriterionScoringPolicyApplier().apply(
  const CarsAssessmentInputPreparer().prepare(input),
  policy: policy,
);

class TestApprovedScoringPolicy implements CarsApprovedCriterionScoringPolicy {
  final Map<CarsCriterion, double?> outputs;

  TestApprovedScoringPolicy({Map<CarsCriterion, double?>? outputs})
    : outputs =
          outputs ??
          {for (final criterion in CarsCriterion.values) criterion: 70};

  @override
  String? approvedRuleReferenceFor(CarsCriterion criterion) => 'test-only rule';

  @override
  double? scoreFor({
    required CarsCriterion criterion,
    required Object evidence,
  }) => outputs[criterion];
}

void main() {
  group('CarsAssessmentInputPreparer', () {
    test(
      'complete evidence remains typed and scores only through injected policy',
      () {
        final input = completeInput();
        final prepared = prepare(input, policy: TestApprovedScoringPolicy());

        expect(prepared.criteria.length, 6);
        expect(
          prepared.criteria.values.every(
            (criterion) =>
                criterion.inputStatus == CarsAssessmentInputStatus.available,
          ),
          isTrue,
        );
        expect(prepared.hasAllCriterionScores, isTrue);
        expect(prepared.criterionScores.values.toSet(), {70.0});
        expect(
          prepared.criteria[CarsCriterion.publicDestinationRating]!.evidence,
          same(input.destination),
        );
        expect(
          prepared.criteria[CarsCriterion.weatherSuitability]!.evidence,
          same(input.weather),
        );
        expect(
          prepared
              .criteria[CarsCriterion.availableTravelTimeCompatibility]!
              .evidence,
          same(input.travel),
        );
      },
    );

    test(
      'policy boundary accepts both endpoints of the current score scale',
      () {
        for (final endpoint in [
          CarsScoreContract.minimum,
          CarsScoreContract.maximum,
        ]) {
          final prepared = prepare(
            completeInput(),
            policy: TestApprovedScoringPolicy(
              outputs: {
                for (final criterion in CarsCriterion.values)
                  criterion: endpoint,
              },
            ),
          );

          expect(prepared.criterionScores.values, everyElement(endpoint));
          expect(prepared.hasAllCriterionScores, isTrue);
        }
      },
    );

    test(
      'without a scoring rule, assessed evidence never becomes a numeric score',
      () {
        final prepared = prepare(completeInput());

        expect(
          prepared.criteria.values.every(
            (criterion) => criterion.criterionScore == null,
          ),
          isTrue,
        );
        expect(
          prepared.criteria.values.every(
            (criterion) =>
                criterion.scoreStatus ==
                CarsScorePreparationStatus.noApprovedRule,
          ),
          isTrue,
        );
        expect(prepared.hasAllCriterionScores, isFalse);
      },
    );

    test(
      'partial inputs preserve individual states and leave missing scores null',
      () {
        final input = completeInput(
          weatherCoverage: WeatherForecastCoverage.partial,
          budgetAssessment: budget(BudgetAssessmentStatus.insufficientData),
          interest: CarsInterestActivityMatchAssessment(
            status: CarsInterestActivityMatchStatus
                .unsupportedPreferenceIdentifiers,
          ),
        );
        final prepared = prepare(input, policy: TestApprovedScoringPolicy());

        expect(
          prepared.criteria[CarsCriterion.weatherSuitability]!.inputStatus,
          CarsAssessmentInputStatus.insufficientData,
        );
        expect(
          prepared.criteria[CarsCriterion.budgetCompatibility]!.inputStatus,
          CarsAssessmentInputStatus.insufficientData,
        );
        expect(
          prepared.criteria[CarsCriterion.interestActivityMatch]!.inputStatus,
          CarsAssessmentInputStatus.unsupported,
        );
        expect(
          prepared.criterionScores[CarsCriterion.weatherSuitability],
          isNull,
        );
        expect(
          prepared.criterionScores[CarsCriterion.budgetCompatibility],
          isNull,
        );
        expect(
          prepared.criterionScores[CarsCriterion.interestActivityMatch],
          isNull,
        );
        expect(
          prepared.criterionScores[CarsCriterion.publicDestinationRating],
          70,
        );
      },
    );

    test('all unavailable evidence produces no numeric scores', () {
      final input = CarsAssessmentPreparationInput(
        destination: destination(includeRating: false),
        interestActivityMatch: CarsInterestActivityMatchAssessment(
          status: CarsInterestActivityMatchStatus.mappingUnavailable,
        ),
        preferencesConfirmed: false,
        weather: null,
        budget: null,
        travel: null,
        assessedAt: _now,
      );
      final prepared = prepare(input);

      expect(
        prepared.criterionScores.values.every((score) => score == null),
        isTrue,
      );
      expect(
        prepared.criteria[CarsCriterion.publicDestinationRating]!.inputStatus,
        CarsAssessmentInputStatus.unavailable,
      );
      expect(
        prepared.criteria[CarsCriterion.weatherSuitability]!.inputStatus,
        CarsAssessmentInputStatus.unavailable,
      );
      expect(
        prepared.criteria[CarsCriterion.travelDistanceSuitability]!.inputStatus,
        CarsAssessmentInputStatus.unavailable,
      );
    });

    test('activity evidence states remain distinct and unscored', () {
      final cases =
          <CarsInterestActivityMatchStatus, CarsAssessmentInputStatus>{
            CarsInterestActivityMatchStatus.activityRelationshipsIncomplete:
                CarsAssessmentInputStatus.insufficientData,
            CarsInterestActivityMatchStatus.duplicateActivityIdentifiers:
                CarsAssessmentInputStatus.invalid,
            CarsInterestActivityMatchStatus.invalidActivityEvidence:
                CarsAssessmentInputStatus.invalid,
            CarsInterestActivityMatchStatus.inactiveActivityRecords:
                CarsAssessmentInputStatus.insufficientData,
            CarsInterestActivityMatchStatus.staleActivityEvidence:
                CarsAssessmentInputStatus.stale,
          };
      for (final entry in cases.entries) {
        final prepared = prepare(
          completeInput(
            interest: CarsInterestActivityMatchAssessment(status: entry.key),
          ),
          policy: TestApprovedScoringPolicy(),
        );
        final criterion =
            prepared.criteria[CarsCriterion.interestActivityMatch]!;
        expect(criterion.inputStatus, entry.value);
        expect(criterion.criterionScore, isNull);
        expect(
          prepared.criterionScores[CarsCriterion.interestActivityMatch],
          isNull,
        );
      }
    });

    test('stale rating, weather, and route evidence cannot be scored', () {
      final prepared = prepare(
        completeInput(
          record: destination(freshUntil: DateTime.utc(2026, 11, 17)),
          weatherCoverage: WeatherForecastCoverage.stale,
          travelAssessment: travel(stale: true),
        ),
        policy: TestApprovedScoringPolicy(),
      );

      expect(
        prepared.criteria[CarsCriterion.publicDestinationRating]!.inputStatus,
        CarsAssessmentInputStatus.stale,
      );
      expect(
        prepared.criteria[CarsCriterion.weatherSuitability]!.inputStatus,
        CarsAssessmentInputStatus.stale,
      );
      expect(
        prepared.criteria[CarsCriterion.travelDistanceSuitability]!.inputStatus,
        CarsAssessmentInputStatus.stale,
      );
      expect(
        prepared.criterionScores[CarsCriterion.publicDestinationRating],
        isNull,
      );
      expect(
        prepared.criterionScores[CarsCriterion.weatherSuitability],
        isNull,
      );
      expect(
        prepared.criterionScores[CarsCriterion.travelDistanceSuitability],
        isNull,
      );
    });

    test(
      'invalid rating and unconfirmed or unsupported preferences remain unscored',
      () {
        final invalidRating = prepare(
          completeInput(record: destination(rating: 7)),
          policy: TestApprovedScoringPolicy(),
        );
        expect(
          invalidRating
              .criteria[CarsCriterion.publicDestinationRating]!
              .inputStatus,
          CarsAssessmentInputStatus.invalid,
        );
        expect(
          invalidRating.criterionScores[CarsCriterion.publicDestinationRating],
          isNull,
        );

        final unconfirmed = prepare(
          completeInput(preferencesConfirmed: false),
          policy: TestApprovedScoringPolicy(),
        );
        expect(
          unconfirmed
              .criteria[CarsCriterion.interestActivityMatch]!
              .inputStatus,
          CarsAssessmentInputStatus.insufficientData,
        );
        expect(
          unconfirmed.criterionScores[CarsCriterion.interestActivityMatch],
          isNull,
        );
      },
    );

    test(
      'default-like zero without provenance is insufficient, not scored',
      () {
        final prepared = prepare(
          completeInput(record: destination(rating: 0, source: null)),
          policy: TestApprovedScoringPolicy(),
        );
        final rating =
            prepared.criteria[CarsCriterion.publicDestinationRating]!;

        expect(rating.inputStatus, CarsAssessmentInputStatus.insufficientData);
        expect(rating.criterionScore, isNull);
        expect(
          rating.scoreStatus,
          CarsScorePreparationStatus.evidenceNotScoreable,
        );
      },
    );

    test('verified zero remains evidence but has no unapproved score', () {
      final prepared = prepare(completeInput(record: destination(rating: 0)));
      final rating = prepared.criteria[CarsCriterion.publicDestinationRating]!;

      expect(rating.inputStatus, CarsAssessmentInputStatus.available);
      expect(rating.evidence, isA<DestinationRecord>());
      expect(rating.criterionScore, isNull);
      expect(rating.scoreStatus, CarsScorePreparationStatus.noApprovedRule);
    });

    test('rating with missing source or retrieval time remains unscored', () {
      for (final record in [
        destination(source: null),
        destination(includeTimestamps: false),
      ]) {
        final prepared = prepare(
          completeInput(record: record),
          policy: TestApprovedScoringPolicy(),
        );
        final rating =
            prepared.criteria[CarsCriterion.publicDestinationRating]!;

        expect(rating.inputStatus, CarsAssessmentInputStatus.insufficientData);
        expect(rating.criterionScore, isNull);
      }
    });

    test('no selected preference is not an assumed match or zero score', () {
      final prepared = prepare(
        completeInput(
          interest: CarsInterestActivityMatchAssessment(
            status: CarsInterestActivityMatchStatus.noPreferenceSelected,
          ),
        ),
      );
      expect(
        prepared.criteria[CarsCriterion.interestActivityMatch]!.inputStatus,
        CarsAssessmentInputStatus.notApplicable,
      );
      expect(
        prepared.criterionScores[CarsCriterion.interestActivityMatch],
        isNull,
      );
    });

    test(
      'invalid policy output is rejected instead of passed to the engine',
      () {
        final prepared = prepare(
          completeInput(),
          policy: TestApprovedScoringPolicy(
            outputs: {
              for (final criterion in CarsCriterion.values) criterion: 101,
            },
          ),
        );

        expect(
          prepared.criterionScores.values.every((score) => score == null),
          isTrue,
        );
        expect(
          prepared.criteria.values.every(
            (criterion) =>
                criterion.scoreStatus ==
                CarsScorePreparationStatus.invalidRuleOutput,
          ),
          isTrue,
        );
      },
    );

    test(
      'existing CARS engine rejects prepared missing inputs without redistribution',
      () {
        final prepared = prepare(
          completeInput(weatherCoverage: WeatherForecastCoverage.unavailable),
        );
        final engine = CarsRecommendationEngine(
          weights: {
            for (final criterion in CarsCriterion.values) criterion: 1 / 6,
          },
          eligibilityEvaluator: CarsEligibilityEvaluator(
            CarsEligibilityPolicy(
              approvedStatuses: {'approved'},
              accreditedStatuses: {'accredited'},
            ),
          ),
        );
        final result = engine.rank([
          CarsCandidate(
            destinationId: prepared.destinationId,
            destinationName: prepared.destinationName,
            existsInDataset: true,
            approvalStatus: 'approved',
            accreditationStatus: 'accredited',
            criterionScores: prepared.criterionScores,
          ),
        ]);

        expect(result.ranked, isEmpty);
        expect(
          result.excluded.single.outcome,
          CarsCandidateOutcome.insufficientData,
        );
        expect(result.excluded.single.recommendationScore, isNull);
        expect(
          result.excluded.single.missingCriteria,
          contains('weatherSuitability'),
        );
      },
    );
  });
}
