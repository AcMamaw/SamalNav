import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/cars_assessment_input_preparer.dart';
import 'package:samal_nav/algorithms/cars_budget_assessment.dart';
import 'package:samal_nav/algorithms/cars_engine.dart';
import 'package:samal_nav/algorithms/cars_interest_activity_matcher.dart';
import 'package:samal_nav/algorithms/cars_travel_assessment.dart';
import 'package:samal_nav/models/cars_models.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';
import 'package:samal_nav/services/cars_recommendation_provider.dart';
import 'package:samal_nav/services/open_weather_map_service.dart';

final _now = DateTime.utc(2026, 11, 18, 4);
const _id = 'destination-test';
const _testWeights = <CarsCriterion, double>{
  CarsCriterion.interestActivityMatch: 1 / 6,
  CarsCriterion.publicDestinationRating: 1 / 6,
  CarsCriterion.weatherSuitability: 1 / 6,
  CarsCriterion.budgetCompatibility: 1 / 6,
  CarsCriterion.travelDistanceSuitability: 1 / 6,
  CarsCriterion.availableTravelTimeCompatibility: 1 / 6,
};

DestinationRecord _destination({
  DestinationRatingDataState ratingState = DestinationRatingDataState.available,
  DestinationRatingVerification verification =
      DestinationRatingVerification.verified,
  double? rating = 4,
  DestinationRecordSource source = DestinationRecordSource.database,
}) => DestinationRecord(
  id: _id,
  name: 'Test destination',
  location: 'Test location',
  lat: 10,
  lng: 10,
  category: 'Test',
  rating: rating,
  ratingDataState: ratingState,
  ratingVerification: verification,
  ratingSource: 'approved rating source',
  ratingRetrievedAt: DateTime.utc(2026, 11, 17),
  ratingFreshUntil: DateTime.utc(2026, 11, 20),
  status: 'active',
  isVerified: true,
  source: source,
  hasUsableCoordinates: true,
  hasUsableVisitDuration: true,
);

WeatherForecastResult _weather(WeatherForecastCoverage coverage) =>
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

CarsBudgetAssessment _budget({bool complete = true}) => CarsBudgetAssessment(
  status: complete
      ? BudgetAssessmentStatus.withinBudget
      : BudgetAssessmentStatus.insufficientData,
  currency: complete ? 'PHP' : null,
  knownSubtotal: complete ? 100 : null,
  totalCost: complete ? 100 : null,
  effectiveBudgetMaximum: complete ? 500 : null,
  groupSize: 1,
  adults: 1,
  children: 0,
  elders: 0,
  missingInformation: complete ? const [] : const ['Cost data is incomplete.'],
  costBreakdown: const {},
);

CarsTravelAssessment _travel({bool complete = true}) {
  final leg = TravelLegAssessment(
    fromDestinationId: null,
    toDestinationId: _id,
    kind: TravelLegKind.originToFirstStop,
    straightLineKm: 9,
    routeDistanceKm: complete ? 11 : null,
    estimatedTravelMinutes: complete ? 20 : null,
    state: complete
        ? TravelEstimateState.available
        : TravelEstimateState.unavailable,
    explanation: complete ? 'Fresh route.' : 'Route unavailable.',
    source: 'test route provider',
    retrievedAt: _now,
  );
  return CarsTravelAssessment(
    days: [
      TravelDayAssessment(
        dayNumber: 1,
        itineraryDate: DateTime(2026, 11, 18),
        availableMinutes: 240,
        totalStraightLineKm: 9,
        totalRouteDistanceKm: complete ? 11 : null,
        totalEstimatedTravelMinutes: complete ? 20 : null,
        timeCompatibility: complete
            ? AvailableTimeCompatibility.withinAvailableTime
            : AvailableTimeCompatibility.unknown,
        legs: [leg],
        limitations: complete ? const [] : const ['No route.'],
      ),
    ],
    limitations: const [],
  );
}

CarsAssessmentPreparationInput _input({
  DestinationRecord? destination,
  CarsInterestActivityMatchAssessment? interest,
  bool preferencesConfirmed = true,
  WeatherForecastCoverage weatherCoverage = WeatherForecastCoverage.available,
  bool withBudget = true,
  bool budgetComplete = true,
  bool withTravel = true,
  bool travelComplete = true,
}) => CarsAssessmentPreparationInput(
  destination: destination ?? _destination(),
  interestActivityMatch:
      interest ??
      CarsInterestActivityMatchAssessment(
        status: CarsInterestActivityMatchStatus.matched,
        matchedPreferenceIdentifiers: const {'interest'},
        matchedActivityIdentifiers: const {'activity'},
      ),
  preferencesConfirmed: preferencesConfirmed,
  weather: _weather(weatherCoverage),
  budget: withBudget ? _budget(complete: budgetComplete) : null,
  travel: withTravel ? _travel(complete: travelComplete) : null,
  assessedAt: _now,
);

CarsRecommendationAssessmentRecord _record(
  CarsAssessmentPreparationInput input,
) => CarsRecommendationAssessmentRecord(
  assessmentInput: input,
  eligibility: CarsRecommendationEligibilityInput(
    existsInDataset: true,
    approvalStatus: 'approved',
    accreditationStatus: 'accredited',
  ),
);

class _AssessmentSource implements CarsRecommendationAssessmentSource {
  final List<CarsRecommendationAssessmentRecord> records;
  TripConfiguration? receivedTrip;

  _AssessmentSource(this.records);

  @override
  Future<List<CarsRecommendationAssessmentRecord>> loadAssessments(
    TripConfiguration trip,
  ) async {
    receivedTrip = trip;
    return records;
  }
}

class _FailingAssessmentSource implements CarsRecommendationAssessmentSource {
  @override
  Future<List<CarsRecommendationAssessmentRecord>> loadAssessments(
    TripConfiguration trip,
  ) => Future.error(StateError('synthetic source failure'));
}

class _TestPolicy implements CarsApprovedCriterionScoringPolicy {
  final Map<CarsCriterion, double?> scores;
  final Map<CarsCriterion, String?> references;
  final Set<CarsCriterion> invoked = {};

  _TestPolicy({
    Map<CarsCriterion, double?>? scores,
    Map<CarsCriterion, String?>? references,
  }) : scores =
           scores ??
           {for (final criterion in CarsCriterion.values) criterion: 80},
       references =
           references ??
           {
             for (final criterion in CarsCriterion.values)
               criterion: 'test-only-approved-rule',
           };

  @override
  String? approvedRuleReferenceFor(CarsCriterion criterion) =>
      references[criterion];

  @override
  double? scoreFor({
    required CarsCriterion criterion,
    required Object evidence,
  }) {
    invoked.add(criterion);
    return scores[criterion];
  }
}

PreparedCarsRecommendationProvider _provider({
  required CarsRecommendationAssessmentSource source,
  CarsApprovedCriterionScoringPolicy? policy,
}) => PreparedCarsRecommendationProvider(
  source: source,
  engine: CarsRecommendationEngine(
    weights: _testWeights,
    eligibilityEvaluator: CarsEligibilityEvaluator(
      CarsEligibilityPolicy(
        approvedStatuses: {'approved'},
        accreditedStatuses: {'accredited'},
      ),
    ),
  ),
  scoringPolicy: policy,
  createRunId: () => 'test-run-id',
);

TripConfiguration _trip() => TripConfiguration(
  startDate: DateTime(2026, 11, 18),
  durationDays: 1,
  availableHoursPerDay: 4,
  origin: const TripOrigin(latitude: 9, longitude: 9),
  travelMode: PreferredTravelMode.car,
);

void main() {
  group('PreparedCarsRecommendationProvider', () {
    test(
      'prepares evidence and preserves the trip without inventing scores',
      () async {
        final input = _input();
        final source = _AssessmentSource([_record(input)]);
        final trip = _trip();
        final package = await _provider(source: source).recommend(trip);

        expect(source.receivedTrip, same(trip));
        expect(source.receivedTrip!.origin!.latitude, 9);
        expect(source.receivedTrip!.origin!.longitude, 9);
        expect(source.receivedTrip!.durationDays, 1);
        expect(package.assessmentInputs.keys, [_id]);
        expect(package.assessmentInputs[_id]!.criteria.length, 6);
        expect(
          package
              .assessmentInputs[_id]!
              .criteria[CarsCriterion.publicDestinationRating]!
              .evidence,
          same(input.destination),
        );
        expect(
          package
              .assessmentInputs[_id]!
              .criteria[CarsCriterion.publicDestinationRating]!
              .inputStatus,
          CarsAssessmentInputStatus.available,
        );
        expect(package.ranking.ranked, isEmpty);
        expect(
          package.ranking.excluded.single.outcome,
          CarsCandidateOutcome.insufficientData,
        );
        expect(package.ranking.excluded.single.recommendationScore, isNull);
        expect(
          package.assessmentInputs[_id]!.criterionScores.values,
          everyElement(isNull),
        );
        expect(package.runReference.id, 'test-run-id');
      },
    );

    test(
      'interest activity provenance reaches the provider review package',
      () async {
        final retrievedAt = DateTime.utc(2026, 11, 17);
        final assessment = CarsInterestActivityMatchAssessment(
          status: CarsInterestActivityMatchStatus.matched,
          matchedPreferenceIdentifiers: const {'interest-id'},
          matchedActivityIdentifiers: const {'activity-category-id'},
          mappingSourceReference: 'synthetic mapping fixture',
          mappingVersion: 'test-v1',
          activitySourceReference: 'synthetic activity fixture',
          activityRetrievedAt: retrievedAt,
          activityFreshUntil: DateTime.utc(2026, 11, 20),
        );
        final package = await _provider(
          source: _AssessmentSource([_record(_input(interest: assessment))]),
        ).recommend(_trip());

        final evidence =
            package
                    .assessmentInputs[_id]!
                    .criteria[CarsCriterion.interestActivityMatch]!
                    .evidence
                as CarsInterestActivityMatchAssessment;
        expect(evidence.mappingVersion, 'test-v1');
        expect(evidence.activitySourceReference, 'synthetic activity fixture');
        expect(evidence.activityRetrievedAt, retrievedAt);
        expect(evidence.matchedPreferenceIdentifiers, {'interest-id'});
        expect(evidence.matchedActivityIdentifiers, {'activity-category-id'});
        expect(
          package.assessmentInputs[_id]!.criterionScores[CarsCriterion
              .interestActivityMatch],
          isNull,
        );
        expect(package.ranking.ranked, isEmpty);
      },
    );

    test(
      'all-unavailable assessments produce no ranked recommendations',
      () async {
        final input = _input(
          destination: _destination(
            ratingState: DestinationRatingDataState.missing,
            verification: DestinationRatingVerification.unknown,
            rating: null,
          ),
          interest: CarsInterestActivityMatchAssessment(
            status: CarsInterestActivityMatchStatus.mappingUnavailable,
          ),
          weatherCoverage: WeatherForecastCoverage.unavailable,
          withBudget: false,
          withTravel: false,
        );
        final package = await _provider(
          source: _AssessmentSource([_record(input)]),
        ).recommend(_trip());

        expect(package.ranking.ranked, isEmpty);
        expect(
          package.ranking.excluded.single.outcome,
          CarsCandidateOutcome.insufficientData,
        );
        expect(package.ranking.excluded.single.missingCriteria, hasLength(6));
        expect(
          package.assessmentInputs[_id]!.criterionScores.values,
          everyElement(isNull),
        );
      },
    );

    test(
      'empty source result stays empty and source failure is surfaced',
      () async {
        final empty = await _provider(
          source: _AssessmentSource(const []),
        ).recommend(_trip());
        expect(empty.destinations, isEmpty);
        expect(empty.ranking.ranked, isEmpty);
        expect(empty.ranking.excluded, isEmpty);
        await expectLater(
          _provider(source: _FailingAssessmentSource()).recommend(_trip()),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'partial evidence without policy stays excluded and evidence is retained',
      () async {
        final input = _input(
          weatherCoverage: WeatherForecastCoverage.partial,
          budgetComplete: false,
          travelComplete: false,
        );
        final package = await _provider(
          source: _AssessmentSource([_record(input)]),
        ).recommend(_trip());
        final prepared = package.assessmentInputs[_id]!;

        expect(package.ranking.ranked, isEmpty);
        expect(
          package.ranking.excluded.single.outcome,
          CarsCandidateOutcome.insufficientData,
        );
        expect(
          prepared.criteria[CarsCriterion.weatherSuitability]!.evidence,
          same(input.weather),
        );
        expect(
          prepared.criteria[CarsCriterion.budgetCompatibility]!.evidence,
          same(input.budget),
        );
        expect(
          prepared.criteria[CarsCriterion.travelDistanceSuitability]!.evidence,
          same(input.travel),
        );
        expect(prepared.criterionScores.values, everyElement(isNull));
      },
    );

    test(
      'valid injected test policy supplies all six inputs to the existing engine',
      () async {
        final source = _AssessmentSource([_record(_input())]);
        final policy = _TestPolicy();
        final package = await _provider(
          source: source,
          policy: policy,
        ).recommend(_trip());

        expect(package.ranking.ranked, hasLength(1));
        expect(package.ranking.excluded, isEmpty);
        expect(
          package.ranking.ranked.single.recommendationScore,
          closeTo(80, 1e-8),
        );
        expect(policy.invoked, CarsCriterion.values.toSet());
        expect(package.assessmentInputs[_id]!.hasAllCriterionScores, isTrue);
      },
    );

    test(
      'stale, invalid, unsupported, and missing evidence is never passed to policy',
      () async {
        final input = _input(
          destination: _destination(
            ratingState: DestinationRatingDataState.available,
            rating: 9,
          ),
          interest: CarsInterestActivityMatchAssessment(
            status: CarsInterestActivityMatchStatus
                .unsupportedPreferenceIdentifiers,
          ),
          weatherCoverage: WeatherForecastCoverage.stale,
          withBudget: false,
          withTravel: false,
        );
        final policy = _TestPolicy();
        final package = await _provider(
          source: _AssessmentSource([_record(input)]),
          policy: policy,
        ).recommend(_trip());
        final criteria = package.assessmentInputs[_id]!.criteria;

        expect(policy.invoked, isEmpty);
        expect(
          criteria[CarsCriterion.publicDestinationRating]!.inputStatus,
          CarsAssessmentInputStatus.invalid,
        );
        expect(
          criteria[CarsCriterion.interestActivityMatch]!.inputStatus,
          CarsAssessmentInputStatus.unsupported,
        );
        expect(
          criteria[CarsCriterion.weatherSuitability]!.inputStatus,
          CarsAssessmentInputStatus.stale,
        );
        expect(package.ranking.ranked, isEmpty);
      },
    );

    test('invalid scores and missing policy references remain null', () async {
      for (final invalidScore in [-0.1, 100.1, double.nan, double.infinity]) {
        final scorePolicy = _TestPolicy(
          scores: {
            for (final criterion in CarsCriterion.values)
              criterion: invalidScore,
          },
        );
        final invalidPackage = await _provider(
          source: _AssessmentSource([_record(_input())]),
          policy: scorePolicy,
        ).recommend(_trip());
        expect(invalidPackage.ranking.ranked, isEmpty);
        expect(
          invalidPackage.ranking.excluded.single.outcome,
          CarsCandidateOutcome.insufficientData,
        );
        expect(
          invalidPackage.assessmentInputs[_id]!.criterionScores.values,
          everyElement(isNull),
        );
      }

      final noReference = _TestPolicy(
        references: {
          for (final criterion in CarsCriterion.values) criterion: null,
        },
      );
      final noReferencePackage = await _provider(
        source: _AssessmentSource([_record(_input())]),
        policy: noReference,
      ).recommend(_trip());
      expect(noReference.invoked, isEmpty);
      expect(noReferencePackage.ranking.ranked, isEmpty);
      expect(
        noReferencePackage.assessmentInputs[_id]!.criterionScores.values,
        everyElement(isNull),
      );
    });

    test(
      'production default remains unavailable and yields no fabricated package',
      () async {
        await expectLater(
          const UnavailableCarsRecommendationProvider().recommend(_trip()),
          throwsA(isA<CarsRecommendationUnavailableException>()),
        );
      },
    );
  });
}
