import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/manual_selection_moga_adapter.dart';
import 'package:samal_nav/algorithms/moga_engine.dart' as moga;
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';

const _idA = '11111111-1111-4111-8111-111111111111';
const _idB = '22222222-2222-4222-8222-222222222222';
const _idC = '33333333-3333-4333-8333-333333333333';

void main() {
  const adapter = ManualSelectionMogaAdapter();
  const configuration = ManualMogaConfiguration(randomSeed: 71);

  group('ManualSelectionMogaAdapter', () {
    test(
      'maps UUIDs to and from one-day engine indexes and preserves Pareto data',
      () {
        final draft = _draft([
          _stop(_idB, order: 1, lat: 7.1),
          _stop(_idA, order: 0, lat: 7.0),
        ]);
        final result = adapter.optimize(draft, configuration: configuration);
        final route = result.oneDay!;

        expect(result.inputDestinationIdsInSelectionOrder, [_idA, _idB]);
        expect(route.destinationIdsInRouteOrder.toSet(), {_idA, _idB});
        expect(route.paretoFront, isNotEmpty);
        for (final candidate in route.paretoFront) {
          expect(candidate.destinationIds.toSet(), {_idA, _idB});
          expect(candidate.objectives, hasLength(3));
        }
        expect(route.selectionPolicy, isNotEmpty);
        expect(route.legDistancesKm.length, route.legTravelMinutes.length);
        expect(result.multiDay, isNull);
        final direct = moga.MogaEngine(
          destinations: [
            const moga.Destination(
              name: 'Destination 0',
              location: 'Samal Island',
              lat: 7,
              lng: 125.7,
              visitHours: 1,
              category: 'Beach',
            ),
            const moga.Destination(
              name: 'Destination 1',
              location: 'Samal Island',
              lat: 7.1,
              lng: 125.71,
              visitHours: 1,
              category: 'Beach',
            ),
          ],
          tourHours: 8,
          randomSeed: 71,
        ).optimizeDayTour();
        expect(route.paretoFront, hasLength(direct.paretoFront.length));
        for (var i = 0; i < route.paretoFront.length; i++) {
          final actual = route.paretoFront[i];
          final expected = direct.paretoFront[i];
          expect(
            actual.destinationIds,
            expected.stopOrder
                .map(
                  (index) => result.inputDestinationIdsInSelectionOrder[index],
                )
                .toList(),
          );
          expect(actual.objectives, hasLength(3));
          expect(expected.fitness, hasLength(3));
          for (var objective = 0; objective < 3; objective++) {
            expect(
              actual.objectives[objective],
              closeTo(expected.fitness[objective], 1e-9),
              reason: 'Pareto candidate $i objective $objective',
            );
          }
        }
        expect(route.totalDistanceKm, closeTo(direct.totalDistanceKm, 1e-9));
      },
    );

    test('preserves multi-day assignment and assigned empty days', () {
      final draft = _draft([
        _stop(_idC, order: 2, day: 3, lat: 7.2),
        _stop(_idA, order: 0, day: 1, lat: 7.0),
        _stop(_idB, order: 1, day: 1, lat: 7.1),
      ], days: 3);
      final result = adapter.optimize(draft, configuration: configuration);
      final itinerary = result.multiDay!;

      expect(itinerary.days, hasLength(3));
      expect(itinerary.days[0].destinationIdsInRouteOrder.toSet(), {
        _idA,
        _idB,
      });
      expect(itinerary.days[1].destinationIdsInRouteOrder, isEmpty);
      expect(itinerary.days[2].destinationIdsInRouteOrder, [_idC]);
      expect(itinerary.days[1].paretoFront, isNotEmpty);
      expect(itinerary.requestedDayCount, 3);
      expect(itinerary.dayCountSatisfied, isTrue);
      expect(
        itinerary.days.expand((day) => day.destinationIdsInRouteOrder).toSet(),
        {_idA, _idB, _idC},
      );
    });

    test('maps infeasible results and violating destination back to UUID', () {
      final draft = _draft([
        _stop(_idA, order: 0, minutes: 600, lat: 7.0),
        _stop(_idB, order: 1, minutes: 600, lat: 7.1),
      ]);
      final result = adapter
          .optimize(draft, configuration: configuration)
          .oneDay!;

      expect(result.feasibility.isFeasible, isFalse);
      expect(result.feasibility.overByHours, greaterThan(0));
      expect(result.destinationIdsInRouteOrder.toSet(), {_idA, _idB});
    });

    test('translates each multi-day violating engine index to its UUID', () {
      final draft = _draft([
        _stop(_idA, order: 0, day: 1, minutes: 600),
        _stop(_idB, order: 1, day: 2, minutes: 600, lat: 7.1),
      ], days: 2);
      final itinerary = adapter
          .optimize(draft, configuration: configuration)
          .multiDay!;

      expect(itinerary.isFeasible, isFalse);
      expect(itinerary.violations, hasLength(2));
      expect(
        itinerary.violations
            .map((violation) => violation.destinationId)
            .toSet(),
        {_idA, _idB},
      );
      expect(itinerary.violations.map((violation) => violation.dayNumber), [
        1,
        2,
      ]);
      expect(
        itinerary.violations.every((violation) => violation.overByHours > 0),
        isTrue,
      );
    });

    test('does not mutate the original draft during optimization', () {
      final draft = _draft([_stop(_idA, order: 0)]);
      final stopsBefore = List<DraftStop>.of(draft.stops);
      final updatedAtBefore = draft.updatedAt;
      adapter.optimize(draft, configuration: configuration);
      expect(draft.stops, stopsBefore);
      expect(draft.updatedAt, updatedAtBefore);
      expect(draft.stage, DraftStage.readyForOptimization);
    });

    test('rejects an empty draft and a draft with no included stops', () {
      expect(
        () => adapter.optimize(_draft(const []), configuration: configuration),
        throwsA(isA<DraftValidationException>()),
      );
      expect(
        () => adapter.optimize(
          _draft([_stop(_idA, order: 0, included: false)]),
          configuration: configuration,
        ),
        throwsA(isA<DraftValidationException>()),
      );
    });

    test('rejects invalid and fallback destination identities', () {
      final invalidId = _stop('fb-001', order: 0);
      final fallback = _stop(
        _idA,
        order: 0,
        source: DestinationRecordSource.fallback,
      );
      expect(
        () =>
            adapter.optimize(_draft([invalidId]), configuration: configuration),
        throwsA(isA<DraftValidationException>()),
      );
      expect(
        () =>
            adapter.optimize(_draft([fallback]), configuration: configuration),
        throwsA(isA<DraftValidationException>()),
      );
    });

    test('rejects database destinations that are unverified or inactive', () {
      final unverified = _stop(_idA, order: 0, isVerified: false);
      final inactive = _stop(_idB, order: 1, status: 'inactive');
      expect(
        () => adapter.optimize(
          _draft([unverified]),
          configuration: configuration,
        ),
        throwsA(isA<DraftValidationException>()),
      );
      expect(
        () =>
            adapter.optimize(_draft([inactive]), configuration: configuration),
        throwsA(isA<DraftValidationException>()),
      );
    });

    test('rejects missing coordinates and parser-default visit duration', () {
      final missingCoordinates = _stop(_idA, order: 0, omitCoordinates: true);
      final missingDuration = _stop(_idB, order: 1, omitDuration: true);
      expect(
        () => adapter.optimize(
          _draft([missingCoordinates]),
          configuration: configuration,
        ),
        throwsA(isA<DraftValidationException>()),
      );
      expect(
        () => adapter.optimize(
          _draft([missingDuration]),
          configuration: configuration,
        ),
        throwsA(isA<DraftValidationException>()),
      );
      expect(
        () => adapter.optimize(
          _draft([_stop(_idC, order: 2, lat: 91)]),
          configuration: configuration,
        ),
        throwsA(isA<DraftValidationException>()),
      );
      expect(
        () => adapter.optimize(
          _draft([_stop(_idC, order: 2, minutes: -1)]),
          configuration: configuration,
        ),
        throwsA(isA<DraftValidationException>()),
      );
    });

    test('rejects invalid day assignments and unassigned multi-day stops', () {
      expect(
        () => adapter.optimize(
          _draft([_stop(_idA, order: 0, day: 2)]),
          configuration: configuration,
        ),
        throwsA(isA<DraftValidationException>()),
      );
      expect(
        () => adapter.optimize(
          _draft([_stop(_idA, order: 0)], days: 2),
          configuration: configuration,
        ),
        throwsA(isA<DraftValidationException>()),
      );
    });

    test(
      'rejects invalid trip configuration and non-manual planning methods',
      () {
        expect(
          () => adapter.optimize(
            _draft([_stop(_idA, order: 0)], days: 0),
            configuration: configuration,
          ),
          throwsA(isA<DraftValidationException>()),
        );
        final circuitDraft = _draft([
          _stop(_idA, order: 0),
        ], method: PlanningMethod.circuitBased);
        expect(
          () => adapter.optimize(circuitDraft, configuration: configuration),
          throwsA(isA<DraftValidationException>()),
        );
      },
    );
  });
}

ItineraryDraft _draft(
  List<DraftStop> stops, {
  int days = 1,
  PlanningMethod method = PlanningMethod.manualSelection,
}) => ItineraryDraft(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  method: method,
  stage: DraftStage.readyForOptimization,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  trip: TripConfiguration(durationDays: days, availableHoursPerDay: 8),
  stops: stops,
);

DraftStop _stop(
  String id, {
  required int order,
  int? day,
  int minutes = 60,
  double lat = 7.0,
  bool included = true,
  DestinationRecordSource source = DestinationRecordSource.database,
  bool omitCoordinates = false,
  bool omitDuration = false,
  bool isVerified = true,
  String status = 'active',
}) {
  final json = <String, dynamic>{
    'id': id,
    'name': 'Destination $order',
    'location': 'Samal Island',
    'category': 'Beach',
    'status': status,
    'is_verified': isVerified,
    'lng': 125.7 + order * 0.01,
    'entrance_fee': 0,
  };
  if (!omitCoordinates) json['lat'] = lat;
  if (!omitDuration) json['average_stay_minutes'] = minutes;
  final record = DestinationRecord.fromJson(json, source: source);
  return DraftStop(
    destinationId: id,
    destination: DestinationDisplaySnapshot.fromRecord(record),
    selectionOrder: order,
    assignedDay: day,
    provenance: {const StopProvenance.manual()},
    isIncluded: included,
  );
}
