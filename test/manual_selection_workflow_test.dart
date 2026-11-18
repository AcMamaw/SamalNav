import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/manual_selection_moga_adapter.dart';
import 'package:samal_nav/algorithms/manual_selection_workflow.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';

const _idA = '11111111-1111-4111-8111-111111111111';
const _idB = '22222222-2222-4222-8222-222222222222';
const _idC = '33333333-3333-4333-8333-333333333333';

void main() {
  const builder = ManualSelectionDraftBuilder();
  const mapper = ManualSelectionResultMapper();
  final destinations = [
    _destination(_idA, 'A', latitude: 7.0),
    _destination(_idB, 'B', latitude: 7.1),
    _destination(_idC, 'C', latitude: 7.2),
  ];

  group('Manual selection draft workflow', () {
    test('moves only within a day and refuses boundary moves', () {
      final dayOne = <String>{_idA, _idB, _idC};

      expect(
        moveDestinationWithinDay(dayOne, destinationId: _idA, offset: -1),
        isFalse,
      );
      expect(
        moveDestinationWithinDay(dayOne, destinationId: _idC, offset: 1),
        isFalse,
      );
      expect(dayOne.toList(), [_idA, _idB, _idC]);

      expect(
        moveDestinationWithinDay(dayOne, destinationId: _idB, offset: -1),
        isTrue,
      );
      expect(dayOne.toList(), [_idB, _idA, _idC]);
      expect(
        moveDestinationWithinDay(dayOne, destinationId: _idB, offset: 1),
        isTrue,
      );
      expect(dayOne.toList(), [_idA, _idB, _idC]);
    });

    test(
      'starts a reviewable, unoptimized manual draft with stable IDs/order',
      () {
        final draft = builder.build(
          destinations: destinations,
          daySelections: const [
            [_idC, _idA, _idB],
          ],
          trip: _trip(),
          now: DateTime.utc(2026, 1, 2),
        );

        expect(draft.method, PlanningMethod.manualSelection);
        expect(draft.stage, DraftStage.draftReview);
        expect(draft.optimizationResult, isNull);
        expect(draft.selectedCircuits, isEmpty);
        expect(draft.carsRunReference, isNull);
        expect(draft.stops.map((stop) => stop.destinationId), [
          _idC,
          _idA,
          _idB,
        ]);
        expect(draft.stops.map((stop) => stop.selectionOrder), [0, 1, 2]);
        expect(
          draft.stops.every(
            (stop) =>
                stop.provenance.single.kind ==
                StopProvenanceKind.manualSelection,
          ),
          isTrue,
        );
        expect(draft.validate().isValid, isTrue);
      },
    );

    test(
      'rebuild preserves draft identity and reflects removals/config edits',
      () {
        final createdAt = DateTime.utc(2026, 1, 2);
        final original = builder.build(
          destinations: destinations,
          daySelections: const [
            [_idC, _idA, _idB],
          ],
          trip: _trip(),
          now: createdAt,
        );
        final updatedAt = DateTime.utc(2026, 1, 3);
        final updated = builder.build(
          destinations: destinations,
          daySelections: const [
            [_idC, _idB],
          ],
          trip: _trip(hours: 7, days: 1),
          existingDraft: original,
          now: updatedAt,
        );

        expect(updated.id, original.id);
        expect(updated.createdAt, original.createdAt);
        expect(updated.updatedAt, updatedAt);
        expect(updated.stops.map((stop) => stop.destinationId), [_idC, _idB]);
        expect(updated.trip.availableHoursPerDay, 7);
        expect(updated.optimizationResult, isNull);
      },
    );

    test('preserves assigned day groups and trip configuration', () {
      final trip = TripConfiguration(
        startDate: DateTime.utc(2026, 2, 1),
        durationDays: 2,
        availableHoursPerDay: 8,
        totalGroupSize: 5,
        childrenCount: 1,
        eldersCount: 1,
        origin: const TripOrigin(
          latitude: 7.1,
          longitude: 125.7,
          label: 'Hotel',
        ),
        travelMode: PreferredTravelMode.publicTransportation,
      );
      final draft = builder.build(
        destinations: destinations,
        daySelections: const [
          [_idB, _idA],
          [_idC],
        ],
        trip: trip,
      );

      expect(draft.stops.map((stop) => stop.destinationId), [_idB, _idA, _idC]);
      expect(draft.stops.map((stop) => stop.assignedDay), [1, 1, 2]);
      expect(draft.trip.startDate, DateTime.utc(2026, 2, 1));
      expect(draft.trip.adultsCount, 3);
      expect(draft.trip.origin?.label, 'Hotel');
      expect(draft.trip.travelMode, PreferredTravelMode.publicTransportation);
      expect(draft.validate().isValid, isTrue);
    });

    test(
      'reordered builder output preserves stop metadata and day assignment',
      () {
        final transfer = const RequiredTransfer(
          fromDestinationId: _idA,
          toDestinationId: _idC,
          kind: RequiredTransferKind.boat,
        );
        final original = builder.build(
          destinations: destinations,
          daySelections: const [
            [_idA, _idB],
            [_idC],
          ],
          trip: TripConfiguration(
            durationDays: 2,
            availableHoursPerDay: 8,
            requiredTransfers: [transfer],
          ),
        );
        final originalStops = original.stops;
        final withMetadata = ItineraryDraft(
          id: original.id,
          method: original.method,
          stage: original.stage,
          createdAt: original.createdAt,
          updatedAt: original.updatedAt,
          trip: original.trip,
          stops: [
            for (final stop in originalStops)
              DraftStop(
                destinationId: stop.destinationId,
                destination: stop.destination,
                selectionOrder: stop.selectionOrder,
                assignedDay: stop.assignedDay,
                provenance: {
                  StopProvenance(
                    kind: StopProvenanceKind.circuit,
                    sourceId: 'circuit-1',
                    sourceName: 'North Samal',
                  ),
                },
                selectedActivityIds: ['activity-${stop.destinationId}'],
                isIncluded: stop.destinationId != _idA,
              ),
          ],
        );
        final dayOne = <String>{_idA, _idB};
        expect(
          moveDestinationWithinDay(dayOne, destinationId: _idB, offset: -1),
          isTrue,
        );
        final reordered = builder.build(
          destinations: destinations,
          daySelections: [
            dayOne.toList(),
            const [_idC],
          ],
          trip: withMetadata.trip,
          existingDraft: withMetadata,
        );

        expect(reordered.stops.map((stop) => stop.destinationId), [
          _idB,
          _idA,
          _idC,
        ]);
        expect(reordered.stops.map((stop) => stop.assignedDay), [1, 1, 2]);
        expect(
          reordered.stops.first.provenance,
          withMetadata.stops[1].provenance,
        );
        expect(reordered.stops.first.selectedActivityIds, ['activity-$_idB']);
        expect(reordered.stops[1].isIncluded, isFalse);
        expect(reordered.trip.requiredTransfers.single, same(transfer));
      },
    );

    test(
      'optimization is explicit and maps adapter result UUIDs back for display',
      () {
        final draft = builder.build(
          destinations: destinations,
          daySelections: const [
            [_idC],
            [_idA, _idB],
          ],
          trip: _trip(days: 2),
        );
        expect(draft.optimizationResult, isNull);

        final ready = draft.transitionTo(DraftStage.readyForOptimization);
        final optimizing = ready.transitionTo(DraftStage.optimizing);
        final result = const ManualSelectionMogaAdapter().optimize(
          ready,
          configuration: const ManualMogaConfiguration(randomSeed: 9),
        );
        expect(result.multiDay!.days, hasLength(2));
        expect(result.multiDay!.days[0].destinationIdsInRouteOrder, [_idC]);
        expect(result.multiDay!.days[1].destinationIdsInRouteOrder.toSet(), {
          _idA,
          _idB,
        });
        expect(
          result.multiDay!.days
              .expand((day) => day.destinationIdsInRouteOrder)
              .toSet(),
          {_idA, _idB, _idC},
        );

        final completed = optimizing
            .transitionTo(DraftStage.optimizationResults, result: result)
            .transitionTo(DraftStage.itineraryReview);
        final mapped = mapper.map(result, destinations);
        expect(completed.optimizationResult, same(result));
        expect(mapped.itineraryResult!.days, hasLength(2));
        expect(
          mapped.itineraryResult!.days
              .expand((day) => day.stopOrder)
              .map((index) => destinations[index].id)
              .toSet(),
          {_idA, _idB, _idC},
        );
        expect(mapped.routeSegments, hasLength(2));
      },
    );

    test(
      'does not drop infeasible destinations and maps violations to UUIDs',
      () {
        final longStay = [
          _destination(_idA, 'A', latitude: 7.0, minutes: 600),
          _destination(_idB, 'B', latitude: 7.1, minutes: 600),
        ];
        final draft = builder.build(
          destinations: longStay,
          daySelections: const [
            [_idA],
            [_idB],
          ],
          trip: _trip(days: 2),
        );
        final ready = draft.transitionTo(DraftStage.readyForOptimization);
        final result = const ManualSelectionMogaAdapter().optimize(
          ready,
          configuration: const ManualMogaConfiguration(randomSeed: 9),
        );

        expect(result.multiDay!.isFeasible, isFalse);
        expect(
          result.multiDay!.violations.map((item) => item.destinationId).toSet(),
          {_idA, _idB},
        );
        expect(
          result.multiDay!.days
              .expand((day) => day.destinationIdsInRouteOrder)
              .toSet(),
          {_idA, _idB},
        );
      },
    );

    test(
      'one-day result mapping retains UUID identity and Pareto candidates',
      () {
        final draft = builder.build(
          destinations: destinations,
          daySelections: const [
            [_idC, _idA],
          ],
          trip: _trip(),
        );
        final ready = draft.transitionTo(DraftStage.readyForOptimization);
        final result = const ManualSelectionMogaAdapter().optimize(
          ready,
          configuration: const ManualMogaConfiguration(randomSeed: 31),
        );
        final mapped = mapper.map(result, destinations);

        expect(result.inputDestinationIdsInSelectionOrder, [_idC, _idA]);
        expect(result.oneDay!.destinationIdsInRouteOrder.toSet(), {_idA, _idC});
        expect(
          mapped.dayResult!.stopOrder
              .map((index) => destinations[index].id)
              .toSet(),
          {_idA, _idC},
        );
        expect(mapped.itineraryResult, isNull);
        for (final candidate in result.oneDay!.paretoFront) {
          expect(candidate.destinationIds.toSet(), {_idA, _idC});
        }
      },
    );

    test(
      'adapter errors keep missing-data destinations visible in the draft',
      () {
        final incomplete = _destination(
          _idA,
          'A',
          latitude: 7.0,
          omitDuration: true,
        );
        final draft = builder.build(
          destinations: [incomplete],
          daySelections: const [
            [_idA],
          ],
          trip: _trip(),
        );
        final ready = draft.transitionTo(DraftStage.readyForOptimization);

        expect(draft.stops, hasLength(1));
        expect(
          () => const ManualSelectionMogaAdapter().optimize(ready),
          throwsA(isA<DraftValidationException>()),
        );
        expect(draft.stops.single.destinationId, _idA);

        final missingCoordinates = _destination(
          _idB,
          'B',
          latitude: 7.0,
          omitCoordinates: true,
        );
        final missingCoordinateDraft = builder.build(
          destinations: [missingCoordinates],
          daySelections: const [
            [_idB],
          ],
          trip: _trip(),
        );
        expect(
          () => const ManualSelectionMogaAdapter().optimize(
            missingCoordinateDraft.transitionTo(
              DraftStage.readyForOptimization,
            ),
          ),
          throwsA(isA<DraftValidationException>()),
        );
      },
    );

    test(
      'rejects mismatched day groups instead of silently redistributing stops',
      () {
        expect(
          () => builder.build(
            destinations: destinations,
            daySelections: const [
              [_idA],
            ],
            trip: _trip(days: 2),
          ),
          throwsArgumentError,
        );
      },
    );
  });
}

TripConfiguration _trip({int hours = 8, int days = 1}) =>
    TripConfiguration(durationDays: days, availableHoursPerDay: hours);

DestinationRecord _destination(
  String id,
  String name, {
  required double latitude,
  int minutes = 60,
  bool omitDuration = false,
  bool omitCoordinates = false,
}) {
  final json = <String, Object?>{
    'id': id,
    'name': name,
    'location': 'Samal Island',
    'category': 'Beach',
    'status': 'active',
    'is_verified': true,
  };
  if (!omitCoordinates) {
    json['lat'] = latitude;
    json['lng'] = 125.7;
  }
  if (!omitDuration) json['average_stay_minutes'] = minutes;
  return DestinationRecord.fromJson(
    json,
    source: DestinationRecordSource.database,
  );
}
