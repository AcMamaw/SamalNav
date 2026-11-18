import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/cars_engine.dart';
import 'package:samal_nav/algorithms/system_generated_draft_builder.dart';
import 'package:samal_nav/models/cars_models.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';

const _idA = '11111111-1111-4111-8111-111111111111';
const _idB = '22222222-2222-4222-8222-222222222222';

void main() {
  final engine = CarsRecommendationEngine(
    weights: {for (final criterion in CarsCriterion.values) criterion: 1 / 6},
    eligibilityEvaluator: CarsEligibilityEvaluator(
      CarsEligibilityPolicy(
        approvedStatuses: {'approved'},
        accreditedStatuses: {'accredited'},
      ),
    ),
  );
  final ranking = engine.rank([
    _candidate(_idA, 'Island Park'),
    _candidate(
      _idB,
      'Cave Trail',
      scores: {
        for (final criterion in CarsCriterion.values)
          if (criterion != CarsCriterion.weatherSuitability) criterion: 70,
      },
    ),
  ]);
  final destinations = [_destination(_idA, 'Island Park')];

  test('builds an unoptimized CARS draft from tourist-selected results', () {
    final trip = TripConfiguration(
      durationDays: 2,
      availableHoursPerDay: 8,
      origin: const TripOrigin(latitude: 7.1, longitude: 125.7, label: 'Port'),
    );
    final draft = const SystemGeneratedDraftBuilder().build(
      ranking: ranking,
      selectedDestinationIds: const [_idA],
      assignedDays: const {_idA: 2},
      destinations: destinations,
      trip: trip,
      carsRunReference: const CarsRunReference('cars-run-test'),
      now: DateTime.utc(2026, 1, 1),
    );

    expect(draft.method, PlanningMethod.systemGenerated);
    expect(draft.stage, DraftStage.recommendationReview);
    expect(draft.optimizationResult, isNull);
    expect(draft.carsRunReference?.id, 'cars-run-test');
    expect(draft.stops.single.destinationId, _idA);
    expect(draft.stops.single.assignedDay, 2);
    expect(draft.stops.single.selectionOrder, 0);
    expect(
      draft.stops.single.provenance.single.kind,
      StopProvenanceKind.carsRecommendation,
    );
    expect(draft.trip.origin?.label, 'Port');
  });

  test('rejects excluded, unranked, duplicate, or unassigned selections', () {
    final trip = TripConfiguration(durationDays: 2, availableHoursPerDay: 8);
    ItineraryDraft build(List<String> ids, Map<String, int> days) =>
        const SystemGeneratedDraftBuilder().build(
          ranking: ranking,
          selectedDestinationIds: ids,
          assignedDays: days,
          destinations: [
            _destination(_idA, 'Island Park'),
            _destination(_idB, 'Cave Trail'),
          ],
          trip: trip,
          carsRunReference: const CarsRunReference('cars-run-test'),
        );

    expect(() => build(const [_idB], const {_idB: 1}), throwsArgumentError);
    expect(() => build(const [_idA], const {}), throwsArgumentError);
    expect(
      () => build(const [_idA, _idA], const {_idA: 1}),
      throwsArgumentError,
    );
  });

  test(
    'refuses to convert a bundled fallback record into a CARS draft stop',
    () {
      final fallback = DestinationRecord(
        id: _idA,
        name: 'Island Park',
        location: 'Samal Island',
        lat: 7,
        lng: 125,
        category: 'Nature',
        rating: 4,
        status: 'active',
        isVerified: true,
        source: DestinationRecordSource.fallback,
        hasUsableCoordinates: true,
        hasUsableVisitDuration: true,
      );

      expect(
        () => const SystemGeneratedDraftBuilder().build(
          ranking: ranking,
          selectedDestinationIds: const [_idA],
          assignedDays: const {},
          destinations: [fallback],
          trip: TripConfiguration(durationDays: 1, availableHoursPerDay: 8),
          carsRunReference: const CarsRunReference('cars-run-test'),
        ),
        throwsArgumentError,
      );
    },
  );
}

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

DestinationRecord _destination(String id, String name) => DestinationRecord(
  id: id,
  name: name,
  location: 'Samal Island',
  lat: 7.0,
  lng: 125.0,
  category: 'Nature',
  rating: 4.2,
  status: 'active',
  isVerified: true,
  source: DestinationRecordSource.database,
  hasUsableCoordinates: true,
  hasUsableVisitDuration: true,
);
