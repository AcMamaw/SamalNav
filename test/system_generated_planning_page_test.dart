import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/cars_assessment_input_preparer.dart';
import 'package:samal_nav/models/cars_models.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';
import 'package:samal_nav/models/tourist_planning_profile.dart';
import 'package:samal_nav/screens/tourist_screens/cars_recommendation_review_page.dart';
import 'package:samal_nav/screens/tourist_screens/plan_page.dart';
import 'package:samal_nav/screens/tourist_screens/system_generated_planning_page.dart';
import 'package:samal_nav/services/cars_recommendation_provider.dart';
import 'package:samal_nav/services/tourist_planning_profile_service.dart';
import 'package:samal_nav/services/tourist_planning_profile_trip_adapter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _destinationId = '11111111-1111-4111-8111-111111111111';

void main() {
  testWidgets('Plan tab exposes system-generated planning entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlanPage(
          destinationLoader: () async => const [],
          carsRecommendationProvider:
              const UnavailableCarsRecommendationProvider(),
          touristPlanningProfileService: _ProfileService(null),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const Key('open_system_generated_planning')),
      findsOneWidget,
    );
    expect(find.text('Day Escape'), findsOneWidget);
    expect(find.text('Itinerary Escape'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open_system_generated_planning')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('planning_profile_missing')), findsOneWidget);
    expect(find.byType(CarsRecommendationReviewPage), findsNothing);
    await tester.tap(find.byKey(const Key('generate_cars_recommendations')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cars_provider_unavailable')), findsOneWidget);
    expect(
      find.textContaining('approved scoring/weight configuration'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('provider result reaches CARS review and tourist selection', (
    tester,
  ) async {
    final trip = _trip();
    final provider = _Provider((receivedTrip) async {
      expect(identical(receivedTrip, trip), isTrue);
      return _package();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: SystemGeneratedPlanningPage(
          trip: trip,
          provider: provider,
          profileService: _ProfileService(_profileSnapshot(categories: [])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      provider.calls,
      0,
      reason: 'CARS waits for explicit tourist action.',
    );
    expect(
      find.textContaining('No category preference selected.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('generate_cars_recommendations')));
    await tester.pumpAndSettle();

    expect(find.byType(CarsRecommendationReviewPage), findsOneWidget);
    expect(find.textContaining('Starting point:'), findsOneWidget);
    expect(find.textContaining('CARS score 66.67'), findsOneWidget);
    final evidenceFinder = find.byKey(
      const Key('cars_evidence_$_destinationId'),
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(evidenceFinder);
    await tester.pumpAndSettle();
    final forecastEvidenceFinder = find.textContaining(
      'Synthetic forecast evidence prepared for provider handoff.',
    );
    expect(forecastEvidenceFinder, findsOneWidget);
    expect(
      find.textContaining('Weather suitability · available'),
      findsOneWidget,
    );
    expect(find.textContaining('Scoring rule: test-rule-v1'), findsOneWidget);
    expect(
      find.byKey(const Key('cars_select_$_destinationId')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('cars_select_$_destinationId')));
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('cars_day_$_destinationId')),
    );
    await tester.tap(find.byKey(const Key('cars_day_$_destinationId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day 1').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('continue_cars_draft_review')),
    );
    await tester.tap(find.byKey(const Key('continue_cars_draft_review')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('optimize_system_draft')), findsOneWidget);
    expect(
      find.byKey(const Key('system_draft_stop_$_destinationId')),
      findsOneWidget,
    );
    expect(find.textContaining('Assigned day 1'), findsOneWidget);
    expect(
      find.byKey(const Key('accept_system_optimized_itinerary')),
      findsNothing,
    );
    expect(provider.calls, 1);
  });

  testWidgets('default provider reports unavailable instead of scoring', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SystemGeneratedPlanningPage(trip: _trip())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('generate_cars_recommendations')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cars_provider_unavailable')), findsOneWidget);
    expect(find.byType(CarsRecommendationReviewPage), findsNothing);
    expect(find.byKey(const Key('retry_cars_recommendations')), findsOneWidget);
  });

  testWidgets('unconfirmed saved categories never reach the CARS provider', (
    tester,
  ) async {
    final trip = _trip();
    TripConfiguration? received;
    final provider = _Provider((value) async {
      received = value;
      return _package(empty: true);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: SystemGeneratedPlanningPage(
          trip: trip,
          provider: provider,
          profileService: _ProfileService(
            _profileSnapshot(
              categories: ['unverified-category-id'],
              confirmed: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved preferences are unconfirmed'), findsOneWidget);
    expect(find.textContaining('will not be sent to CARS'), findsOneWidget);
    expect(provider.calls, 0);
    await tester.tap(find.byKey(const Key('generate_cars_recommendations')));
    await tester.pumpAndSettle();

    expect(identical(received, trip), isTrue);
    expect(provider.calls, 1);
  });

  testWidgets(
    'explicitly confirmed profile fills only absent supported fields',
    (tester) async {
      final trip = _tripWithOptionalPreferencesMissing();
      TripConfiguration? received;
      final provider = _Provider((value) async {
        received = value;
        return _package(empty: true);
      });
      await tester.pumpWidget(
        MaterialApp(
          home: SystemGeneratedPlanningPage(
            trip: trip,
            provider: provider,
            profileService: _ProfileService(
              _profileSnapshot(categories: ['unverified-id'], confirmed: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('generate_cars_recommendations')));
      await tester.pumpAndSettle();

      expect(received, isNotNull);
      expect(received!.totalGroupSize, 5);
      expect(received!.childrenCount, 1);
      expect(received!.eldersCount, 1);
      expect(received!.travelMode, PreferredTravelMode.walking);
      expect(received!.origin, same(trip.origin));
      expect(received!.startDate, trip.startDate);
      expect(received!.durationDays, trip.durationDays);
      expect(received!.availableHoursPerDay, trip.availableHoursPerDay);
      expect(received!.requiredTransfers, trip.requiredTransfers);
      expect(received!.budgetMinimum, trip.budgetMinimum);
      expect(received!.budgetMaximum, trip.budgetMaximum);
    },
  );

  test(
    'confirmed saved values do not overwrite tourist-entered trip values',
    () {
      final trip = _trip();
      final merged = const TouristPlanningProfileTripAdapter()
          .applyConfirmedDefaults(
            snapshot: _profileSnapshot(categories: [], confirmed: true),
            currentTrip: trip,
          );

      expect(merged.totalGroupSize, trip.totalGroupSize);
      expect(merged.childrenCount, trip.childrenCount);
      expect(merged.eldersCount, trip.eldersCount);
      expect(merged.travelMode, trip.travelMode);
      expect(merged.origin, same(trip.origin));
      expect(merged.startDate, trip.startDate);
      expect(merged.durationDays, trip.durationDays);
      expect(merged.availableHoursPerDay, trip.availableHoursPerDay);
      expect(merged.requiredTransfers, trip.requiredTransfers);
      expect(merged.budgetMinimum, trip.budgetMinimum);
      expect(merged.budgetMaximum, trip.budgetMaximum);
    },
  );

  test('nullable confirmed profile mode never invents a trip mode', () {
    final trip = _tripWithOptionalPreferencesMissing();
    final merged = const TouristPlanningProfileTripAdapter()
        .applyConfirmedDefaults(
          snapshot: _profileSnapshot(
            categories: [],
            confirmed: true,
            travelMode: null,
          ),
          currentTrip: trip,
        );

    expect(merged.travelMode, isNull);
    expect(merged.requiredTransfers, trip.requiredTransfers);
    expect(merged.origin, same(trip.origin));
  });

  testWidgets(
    'profile loading error requires explicit continue with trip inputs',
    (tester) async {
      final trip = _trip();
      TripConfiguration? received;
      final provider = _Provider((value) async {
        received = value;
        return _package(empty: true);
      });
      await tester.pumpWidget(
        MaterialApp(
          home: SystemGeneratedPlanningPage(
            trip: trip,
            provider: provider,
            profileService: _ProfileService(null, error: StateError('offline')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('planning_profile_load_error')),
        findsOneWidget,
      );
      expect(provider.calls, 0);
      await tester.tap(find.byKey(const Key('generate_cars_recommendations')));
      await tester.pumpAndSettle();
      expect(identical(received, trip), isTrue);
    },
  );

  testWidgets('empty provider result and provider errors have clear states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SystemGeneratedPlanningPage(
          trip: _trip(),
          provider: _Provider((_) async => _package(empty: true)),
          profileService: _ProfileService(null),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generate_cars_recommendations')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cars_provider_empty')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: SystemGeneratedPlanningPage(
          trip: _trip(),
          provider: _Provider((_) async => throw StateError('source offline')),
          profileService: _ProfileService(null),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generate_cars_recommendations')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cars_provider_unavailable')), findsOneWidget);
    expect(find.textContaining('source offline'), findsOneWidget);
  });

  testWidgets('loading state is shown while provider resolves', (tester) async {
    final completer = Completer<CarsRecommendationPackage>();
    await tester.pumpWidget(
      MaterialApp(
        home: SystemGeneratedPlanningPage(
          trip: _trip(),
          provider: _Provider((_) => completer.future),
          profileService: _ProfileService(null),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generate_cars_recommendations')));
    await tester.pump();
    expect(
      find.text('Checking available CARS recommendation data…'),
      findsOneWidget,
    );
    completer.completeError(
      const CarsRecommendationUnavailableException('not configured'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('not configured'), findsOneWidget);
  });
}

class _ProfileService extends TouristPlanningProfileService {
  final TouristPlanningProfileSnapshot? snapshot;
  final Object? error;

  _ProfileService(this.snapshot, {this.error})
    : super(
        client: SupabaseClient(
          'http://127.0.0.1:54321',
          'test-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  @override
  Future<TouristPlanningProfileSnapshot?> fetchCurrent() async {
    if (error != null) throw error!;
    return snapshot;
  }
}

class _Provider implements CarsRecommendationProvider {
  final Future<CarsRecommendationPackage> Function(TripConfiguration trip)
  callback;
  int calls = 0;

  _Provider(this.callback);

  @override
  Future<CarsRecommendationPackage> recommend(TripConfiguration trip) {
    calls++;
    return callback(trip);
  }
}

TripConfiguration _trip() => TripConfiguration(
  startDate: DateTime(2027, 4, 5),
  durationDays: 2,
  availableHoursPerDay: 7,
  budgetMinimum: 1000,
  budgetMaximum: 2000,
  budgetBasis: BudgetBasis.totalGroup,
  currency: 'PHP',
  totalGroupSize: 3,
  childrenCount: 1,
  eldersCount: 0,
  origin: const TripOrigin(latitude: 7.1, longitude: 125.7, label: 'Port'),
  travelMode: PreferredTravelMode.publicTransportation,
  requiredTransfers: const [
    RequiredTransfer(
      fromDestinationId: _destinationId,
      toDestinationId: '22222222-2222-4222-8222-222222222222',
      kind: RequiredTransferKind.ferry,
    ),
  ],
);

TripConfiguration _tripWithOptionalPreferencesMissing() => TripConfiguration(
  startDate: DateTime(2027, 4, 5),
  durationDays: 2,
  availableHoursPerDay: 7,
  origin: const TripOrigin(latitude: 7.1, longitude: 125.7, label: 'Port'),
  requiredTransfers: const [
    RequiredTransfer(
      fromDestinationId: _destinationId,
      toDestinationId: '22222222-2222-4222-8222-222222222222',
      kind: RequiredTransferKind.ferry,
    ),
  ],
);

TouristPlanningProfileSnapshot _profileSnapshot({
  required List<String>? categories,
  bool confirmed = false,
  String? travelMode = 'walking',
}) => TouristPlanningProfileSnapshot(
  profile: TouristPlanningProfile.fromJson({
    'id': '22222222-2222-4222-8222-222222222222',
    'user_id': '33333333-3333-4333-8333-333333333333',
    'budget_min': 200,
    'budget_max': 1200,
    'available_hours_per_day': 8,
    'trip_duration_days': 4,
    'preferred_categories': categories,
    'current_lat': 11.0,
    'current_lng': 122.0,
    'travel_mode': travelMode,
    'created_at': '2026-01-01T00:00:00Z',
    'number_of_tourists': 5,
    'children_count': 1,
    'elders_count': 1,
  }),
  preferencesConfirmed: confirmed,
);

CarsRecommendationPackage _package({bool empty = false}) {
  if (empty) {
    return CarsRecommendationPackage(
      ranking: CarsRankingResult(ranked: const [], excluded: const []),
      destinations: const [],
      runReference: const CarsRunReference('cars-run'),
    );
  }
  const scores = <CarsCriterion, double>{
    CarsCriterion.interestActivityMatch: 70,
    CarsCriterion.publicDestinationRating: 80,
    CarsCriterion.weatherSuitability: 60,
    CarsCriterion.budgetCompatibility: 50,
    CarsCriterion.travelDistanceSuitability: 75,
    CarsCriterion.availableTravelTimeCompatibility: 65,
  };
  final result = CarsCandidateResult(
    destinationId: _destinationId,
    destinationName: 'Verified Beach',
    outcome: CarsCandidateOutcome.ranked,
    recommendationScore: 66.67,
    criterionScores: scores,
    weightedContributions: const {
      CarsCriterion.interestActivityMatch: 11.67,
      CarsCriterion.publicDestinationRating: 13.33,
      CarsCriterion.weatherSuitability: 10,
      CarsCriterion.budgetCompatibility: 8.33,
      CarsCriterion.travelDistanceSuitability: 12.5,
      CarsCriterion.availableTravelTimeCompatibility: 10.83,
    },
    eligibility: CarsEligibilityResult(isEligible: true, reasons: const []),
    missingCriteria: const [],
    explanation: 'Test provider supplied a complete CARS result.',
  );
  return CarsRecommendationPackage(
    ranking: CarsRankingResult(ranked: [result], excluded: const []),
    destinations: const [
      DestinationRecord(
        id: _destinationId,
        name: 'Verified Beach',
        location: 'Samal',
        lat: 7.2,
        lng: 125.8,
        category: 'Beach',
        rating: 4.2,
        status: 'active',
        isVerified: true,
        averageStayMinutes: 60,
        source: DestinationRecordSource.database,
        hasUsableCoordinates: true,
        hasUsableVisitDuration: true,
      ),
    ],
    runReference: const CarsRunReference('cars-run'),
    assessmentInputs: {
      _destinationId: CarsPreparedAssessmentInputs(
        destinationId: _destinationId,
        destinationName: 'Verified Beach',
        criteria: {
          for (final criterion in CarsCriterion.values)
            criterion: CarsPreparedCriterionInput(
              criterion: criterion,
              inputStatus: CarsAssessmentInputStatus.available,
              evidence: criterion.name,
              explanation: criterion == CarsCriterion.weatherSuitability
                  ? 'Synthetic forecast evidence prepared for provider handoff.'
                  : 'Synthetic assessment evidence prepared for provider handoff.',
              approvedRuleReference:
                  criterion == CarsCriterion.weatherSuitability
                  ? 'test-rule-v1'
                  : null,
              scoreStatus: CarsScorePreparationStatus.available,
              criterionScore: scores[criterion],
            ),
        },
      ),
    },
  );
}
