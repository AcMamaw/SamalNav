import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';

const _idA = '11111111-1111-4111-8111-111111111111';

void main() {
  group('ItineraryDraft', () {
    test(
      'creates a stable manual draft with empty circuit and CARS references',
      () {
        final now = DateTime.utc(2026, 1, 2);
        final draft = ItineraryDraft.newManual(
          trip: TripConfiguration(durationDays: 1, availableHoursPerDay: 8),
          now: now,
        );

        expect(isUuid(draft.id), isTrue);
        expect(draft.method, PlanningMethod.manualSelection);
        expect(draft.stage, DraftStage.configuring);
        expect(draft.createdAt, now);
        expect(draft.updatedAt, now);
        expect(draft.selectedCircuits, isEmpty);
        expect(draft.carsRunReference, isNull);
      },
    );

    test(
      'retains manual provenance, stable destination identity, and optional data',
      () {
        final stop = _stop(_idA, order: 0);
        final draft = _draft([stop]);
        expect(stop.destinationId, _idA);
        expect(stop.provenance, {const StopProvenance.manual()});
        expect(stop.destination.category, 'Falls');
        expect(stop.destination.categoryId, isNull);
        expect(stop.destination.entrancePrice.amount, 0);
        expect(draft.trip.origin, isNull);
        expect(draft.trip.travelMode, isNull);
        expect(draft.trip.adultsCount, isNull);
        expect(draft.validate().isValid, isTrue);
      },
    );

    test('rejects duplicate active destination IDs during validation', () {
      final draft = _draft([_stop(_idA, order: 0), _stop(_idA, order: 1)]);
      expect(draft.validate().errors, contains(contains('Duplicate included')));
    });

    test(
      'validates trip limits and derives adults only from complete valid group data',
      () {
        final trip = TripConfiguration(
          durationDays: 31,
          availableHoursPerDay: 0,
          budgetMinimum: 100,
          budgetMaximum: 99,
          totalGroupSize: 8,
          childrenCount: 2,
          eldersCount: 1,
          origin: const TripOrigin(latitude: 100, longitude: 125),
        );
        expect(trip.validate(), isNotEmpty);
        expect(trip.adultsCount, 5);
        expect(
          TripConfiguration(
            durationDays: 1,
            availableHoursPerDay: 1,
            totalGroupSize: 3,
            childrenCount: 2,
          ).adultsCount,
          isNull,
        );
        expect(
          TripConfiguration(
            durationDays: 1,
            availableHoursPerDay: 1,
            childrenCount: 1,
          ).validate(),
          isNotEmpty,
        );
      },
    );

    test(
      'manual lifecycle permits review and optimization transitions only',
      () {
        final draft = _draft([
          _stop(_idA, order: 0),
        ], stage: DraftStage.configuring);
        final selecting = draft.transitionTo(DraftStage.selecting);
        final review = selecting.transitionTo(DraftStage.draftReview);
        final ready = review.transitionTo(DraftStage.readyForOptimization);
        final optimizing = ready.transitionTo(DraftStage.optimizing);
        final results = optimizing.transitionTo(
          DraftStage.optimizationResults,
          result: _TestOptimizationResult(),
        );

        expect(results.stage, DraftStage.optimizationResults);
        expect(results.id, draft.id);
        expect(results.createdAt, draft.createdAt);
        expect(results.optimizationResult, isA<_TestOptimizationResult>());
        final itineraryReview = results.transitionTo(
          DraftStage.itineraryReview,
        );
        expect(
          itineraryReview.optimizationResult,
          same(results.optimizationResult),
        );
        expect(
          itineraryReview
              .transitionTo(DraftStage.draftReview)
              .optimizationResult,
          isNull,
        );
        expect(
          () => optimizing.transitionTo(DraftStage.optimizationResults),
          throwsArgumentError,
        );
        expect(() => results.transitionTo(DraftStage.saved), throwsStateError);
        expect(() => draft.transitionTo(DraftStage.saved), throwsStateError);
      },
    );

    test('does not implement circuit lifecycle transitions', () {
      final draft = ItineraryDraft(
        id: 'draft',
        method: PlanningMethod.circuitBased,
        stage: DraftStage.configuring,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        trip: TripConfiguration(durationDays: 1, availableHoursPerDay: 8),
        stops: const [],
      );
      expect(
        () => draft.transitionTo(DraftStage.selecting),
        throwsUnsupportedError,
      );
    });

    test('manual draft cannot carry circuit or CARS source references', () {
      expect(
        () => ItineraryDraft(
          id: 'draft',
          method: PlanningMethod.manualSelection,
          stage: DraftStage.configuring,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          trip: TripConfiguration(durationDays: 1, availableHoursPerDay: 8),
          stops: const [],
          selectedCircuits: const [
            CircuitReference(id: 'circuit', name: 'Circuit'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ItineraryDraft(
          id: 'draft',
          method: PlanningMethod.manualSelection,
          stage: DraftStage.configuring,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          trip: TripConfiguration(durationDays: 1, availableHoursPerDay: 8),
          stops: const [],
          carsRunReference: const CarsRunReference('run'),
        ),
        throwsArgumentError,
      );
    });
  });
}

ItineraryDraft _draft(
  List<DraftStop> stops, {
  DraftStage stage = DraftStage.readyForOptimization,
}) => ItineraryDraft(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  method: PlanningMethod.manualSelection,
  stage: stage,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  trip: TripConfiguration(durationDays: 1, availableHoursPerDay: 8),
  stops: stops,
);

DraftStop _stop(String id, {required int order}) => DraftStop(
  destinationId: id,
  destination: DestinationDisplaySnapshot.fromRecord(
    DestinationRecord.fromJson({
      'id': id,
      'name': 'Destination $order',
      'location': 'Samal Island',
      'category': 'Falls',
      'category_id': null,
      'lat': 7.0 + order * 0.02,
      'lng': 125.7 + order * 0.02,
      'average_stay_minutes': 60,
      'entrance_fee': 0,
    }, source: DestinationRecordSource.database),
  ),
  selectionOrder: order,
  provenance: {const StopProvenance.manual()},
);

class _TestOptimizationResult implements DraftOptimizationResult {}
