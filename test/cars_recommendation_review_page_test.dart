import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/cars_assessment_input_preparer.dart';
import 'package:samal_nav/algorithms/cars_engine.dart';
import 'package:samal_nav/algorithms/cars_interest_activity_matcher.dart';
import 'package:samal_nav/models/cars_models.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';
import 'package:samal_nav/screens/tourist_screens/cars_recommendation_review_page.dart';

const _recommendedId = '11111111-1111-4111-8111-111111111111';
const _insufficientId = '22222222-2222-4222-8222-222222222222';

void main() {
  testWidgets('tourist reviews CARS data and selects before optimization', (
    tester,
  ) async {
    ItineraryDraft? returnedDraft;
    final ranking = _engine().rank([
      _candidate(_recommendedId, 'Island Park'),
      _candidate(
        _insufficientId,
        'Cave Trail',
        scores: {
          for (final criterion in CarsCriterion.values)
            if (criterion != CarsCriterion.weatherSuitability) criterion: 60,
        },
      ),
    ]);
    final interestEvidence = CarsInterestActivityMatchAssessment(
      status: CarsInterestActivityMatchStatus.matched,
      mappingSourceReference: 'synthetic mapping fixture',
      mappingVersion: 'test-v1',
      activitySourceReference: 'synthetic activity fixture',
      activityRetrievedAt: DateTime.utc(2026, 11, 17),
      activityFreshUntil: DateTime.utc(2026, 11, 20),
      matchedPreferenceIdentifiers: const {'interest-id'},
      matchedActivityIdentifiers: const {'activity-id'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                returnedDraft = await Navigator.of(context)
                    .push<ItineraryDraft>(
                      MaterialPageRoute(
                        builder: (_) => CarsRecommendationReviewPage(
                          ranking: ranking,
                          destinations: [_destination()],
                          assessmentInputs: {
                            _insufficientId: CarsPreparedAssessmentInputs(
                              destinationId: _insufficientId,
                              destinationName: 'Cave Trail',
                              criteria: {
                                for (final criterion in CarsCriterion.values)
                                  criterion: CarsPreparedCriterionInput(
                                    criterion: criterion,
                                    inputStatus:
                                        criterion ==
                                            CarsCriterion
                                                .publicDestinationRating
                                        ? CarsAssessmentInputStatus.available
                                        : CarsAssessmentInputStatus
                                              .insufficientData,
                                    evidence:
                                        criterion ==
                                            CarsCriterion.interestActivityMatch
                                        ? interestEvidence
                                        : criterion ==
                                              CarsCriterion
                                                  .publicDestinationRating
                                        ? _ratingEvidence()
                                        : null,
                                    explanation: 'Synthetic evidence fixture.',
                                    approvedRuleReference: null,
                                    scoreStatus: CarsScorePreparationStatus
                                        .evidenceNotScoreable,
                                    criterionScore: null,
                                  ),
                              },
                            ),
                          },
                          trip: TripConfiguration(
                            durationDays: 1,
                            availableHoursPerDay: 8,
                            origin: const TripOrigin(
                              latitude: 7.1,
                              longitude: 125.7,
                              label: 'Tourist-selected port',
                            ),
                          ),
                          carsRunReference: const CarsRunReference(
                            'cars-run-1',
                          ),
                        ),
                      ),
                    );
              },
              child: const Text('Open CARS review'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open CARS review'));
    await tester.pumpAndSettle();

    expect(
      find.text('Context-Aware Recommendation System (CARS)'),
      findsOneWidget,
    );
    expect(find.textContaining('Tourist-selected port'), findsOneWidget);
    for (
      var attempt = 0;
      attempt < 5 &&
          find
              .byKey(const Key('cars_excluded_$_insufficientId'))
              .evaluate()
              .isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
    }
    expect(
      find.byKey(const Key('cars_excluded_$_insufficientId')),
      findsOneWidget,
    );
    expect(
      find.text('Insufficient score data: Weather suitability'),
      findsOneWidget,
    );
    final evidenceTile = find.byKey(
      const Key('cars_evidence_$_insufficientId'),
    );
    await tester.ensureVisible(evidenceTile);
    await tester.tap(evidenceTile);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Mapping source: synthetic mapping fixture'),
      findsOneWidget,
    );
    expect(find.textContaining('Mapping version: test-v1'), findsOneWidget);
    expect(
      find.textContaining('Activity source: synthetic activity fixture'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Verified rating evidence: 4.5/5 (not a CARS score).',
      ),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('cars_select_$_recommendedId')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('cars_select_$_recommendedId')));
    await tester.pump();
    for (
      var attempt = 0;
      attempt < 5 &&
          find
              .byKey(const Key('continue_cars_draft_review'))
              .evaluate()
              .isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
    }
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('continue_cars_draft_review')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(
      find.byKey(const Key('continue_cars_draft_review')),
    );
    await tester.tap(find.byKey(const Key('continue_cars_draft_review')));
    await tester.pumpAndSettle();

    expect(returnedDraft, isNull);
    expect(find.text('Review system-generated itinerary'), findsOneWidget);
    expect(find.byKey(const Key('optimize_system_draft')), findsOneWidget);
    expect(
      find.byKey(const Key('accept_system_optimized_itinerary')),
      findsNothing,
    );
    await tester.ensureVisible(find.byKey(const Key('optimize_system_draft')));
    await tester.tap(find.byKey(const Key('optimize_system_draft')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('accept_system_optimized_itinerary')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('accept_system_optimized_itinerary')),
    );
    await tester.tap(
      find.byKey(const Key('accept_system_optimized_itinerary')),
    );
    await tester.pumpAndSettle();

    expect(returnedDraft, isNotNull);
    expect(returnedDraft!.method, PlanningMethod.systemGenerated);
    expect(returnedDraft!.stage, DraftStage.itineraryReview);
    expect(returnedDraft!.optimizationResult, isNotNull);
    expect(returnedDraft!.stops.single.destinationId, _recommendedId);
    expect(returnedDraft!.carsRunReference?.id, 'cars-run-1');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('multi-day CARS draft requires an explicit day for each pick', (
    tester,
  ) async {
    final ranking = _engine().rank([_candidate(_recommendedId, 'Island Park')]);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CarsRecommendationReviewPage(
                    ranking: ranking,
                    destinations: [_destination()],
                    trip: TripConfiguration(
                      durationDays: 2,
                      availableHoursPerDay: 8,
                    ),
                    carsRunReference: const CarsRunReference('cars-run-2'),
                  ),
                ),
              ),
              child: const Text('Open multi-day CARS review'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open multi-day CARS review'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('cars_select_$_recommendedId')),
    );
    await tester.tap(find.byKey(const Key('cars_select_$_recommendedId')));
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('continue_cars_draft_review')),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(
      find.byKey(const Key('cars_day_$_recommendedId')),
    );
    await tester.tap(find.byKey(const Key('cars_day_$_recommendedId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day 2').last);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('continue_cars_draft_review')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

CarsRecommendationEngine _engine() => CarsRecommendationEngine(
  weights: {for (final criterion in CarsCriterion.values) criterion: 1 / 6},
  eligibilityEvaluator: CarsEligibilityEvaluator(
    CarsEligibilityPolicy(
      approvedStatuses: {'approved'},
      accreditedStatuses: {'accredited'},
    ),
  ),
);

CarsCandidate _candidate(
  String id,
  String name, {
  Map<CarsCriterion, double?>? scores,
}) => CarsCandidate(
  destinationId: id,
  destinationName: name,
  existsInDataset: true,
  approvalStatus: 'approved',
  accreditationStatus: 'accredited',
  criterionScores:
      scores ?? {for (final criterion in CarsCriterion.values) criterion: 80},
);

DestinationRecord _destination() => const DestinationRecord(
  id: _recommendedId,
  name: 'Island Park',
  location: 'Samal Island',
  lat: 7,
  lng: 125,
  category: 'Nature',
  rating: 4.2,
  status: 'active',
  isVerified: true,
  source: DestinationRecordSource.database,
  hasUsableCoordinates: true,
  hasUsableVisitDuration: true,
);

DestinationRecord _ratingEvidence() {
  final now = DateTime.now();
  return DestinationRecord(
    id: _insufficientId,
    name: 'Cave Trail',
    location: 'Samal Island',
    lat: 7,
    lng: 125,
    category: 'Nature',
    rating: 4.5,
    ratingDataState: DestinationRatingDataState.available,
    ratingVerification: DestinationRatingVerification.verified,
    ratingSource: 'synthetic public rating source',
    ratingRetrievedAt: now.subtract(const Duration(hours: 1)),
    ratingFreshUntil: now.add(const Duration(days: 1)),
    status: 'active',
    isVerified: true,
    source: DestinationRecordSource.database,
  );
}
