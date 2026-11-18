import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/moga_engine.dart';
import 'package:samal_nav/state/app_state.dart';
import 'package:latlong2/latlong.dart';

Destination destination(String name, {double hours = 1, double lat = 7, double lng = 126}) =>
    Destination(
      name: name,
      location: 'Samal',
      lat: lat,
      lng: lng,
      visitHours: hours,
      category: 'Beach',
    );

MogaEngine engine(
  List<Destination> destinations, {
  int? seed = 42,
  double hours = 9,
  int daysPopulation = 16,
  int generations = 8,
  MogaStartingPoint? startingPoint,
}) =>
    MogaEngine(
      destinations: destinations,
      tourHours: hours,
      populationSize: daysPopulation,
      generations: generations,
      randomSeed: seed,
      startingPoint: startingPoint,
    );

double roadEstimateKm(Destination from, Destination to) {
  const earthRadiusKm = 6371.0;
  double radians(double degrees) => degrees * 3.141592653589793 / 180;
  final dLat = radians(to.lat - from.lat);
  final dLng = radians(to.lng - from.lng);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(radians(from.lat)) *
          math.cos(radians(to.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)) * 1.3;
}

void main() {
  test('AppState retains separate route segments and a flattened stop sequence', () {
    final dayOne = [const LatLng(7, 126), const LatLng(7.1, 126.1)];
    final dayTwo = [const LatLng(7.5, 126.5), const LatLng(7.6, 126.6)];

    AppState.setActiveRouteSegments([dayOne, dayTwo]);

    expect(AppState.activeRouteSegments, [dayOne, dayTwo]);
    expect(AppState.activeRoutePolyline, [...dayOne, ...dayTwo]);
    expect(AppState.hasActiveRoute, isTrue);
    AppState.clear();
    expect(AppState.activeRouteSegments, isEmpty);
    expect(AppState.hasActiveRoute, isFalse);
  });

  group('MogaEngine', () {
    test('handles empty destination input', () {
      final result = engine(const []).optimizeDayTour();
      expect(result.stopOrder, isEmpty);
      expect(result.totalTimeHours, 0);
      expect(result.feasibility.isFeasible, isTrue);
      expect(result.paretoFront, hasLength(1));
    });

    test('handles one destination and reports visit-time feasibility', () {
      final result = engine([destination('One')]).optimizeDayTour();
      expect(result.stopOrder, [0]);
      expect(result.totalDistanceKm, 0);
      expect(result.totalTimeHours, 1);
      expect(result.feasibility.isFeasible, isTrue);
    });

    test('includes the supplied origin leg in distance, time, and fitness', () {
      const start = MogaStartingPoint(latitude: 7.1, longitude: 125.7);
      final destinationRecord = destination('One', lat: 7.0, lng: 126.0);
      final distance = roadEstimateKm(
        Destination(
          name: 'origin',
          location: '',
          lat: start.latitude,
          lng: start.longitude,
          visitHours: 0,
          category: '',
        ),
        destinationRecord,
      );
      final result = engine([
        destinationRecord,
      ], startingPoint: start).optimizeDayTour();

      expect(result.stopOrder, [0]); // Origin is context, not an extra stop.
      expect(result.totalDistanceKm, closeTo(distance, 1e-9));
      expect(result.totalTimeHours, closeTo(1 + distance / 30, 1e-9));
      expect(result.legDistances, hasLength(1));
      expect(result.legDistances.single, closeTo(distance, 1e-9));
      expect(result.legTravelMins, hasLength(1));
      expect(result.legTravelMins.single, closeTo(distance / 30 * 60, 1e-9));
      expect(result.paretoFront.single.fitness[0], closeTo(distance, 1e-9));
      expect(result.paretoFront.single.fitness[1], -1);
      expect(result.paretoFront.single.fitness[2], 0);
    });

    test('different supplied origins produce different route evaluations', () {
      final stop = destination('One', lat: 7.0, lng: 126.0);
      final near = engine(
        [stop],
        startingPoint: const MogaStartingPoint(latitude: 7, longitude: 126),
      ).optimizeDayTour();
      final far = engine(
        [stop],
        startingPoint: const MogaStartingPoint(latitude: 7.5, longitude: 126.5),
      ).optimizeDayTour();

      expect(near.totalDistanceKm, 0);
      expect(far.totalDistanceKm, greaterThan(near.totalDistanceKm));
      expect(far.totalTimeHours, greaterThan(near.totalTimeHours));
    });

    test('uses origin on first nonempty assigned day only', () {
      const start = MogaStartingPoint(latitude: 7.1, longitude: 125.7);
      final stops = [
        destination('A', lat: 7.0, lng: 126.0),
        destination('B', lat: 7.2, lng: 126.1),
      ];
      final expectedOriginLeg = roadEstimateKm(
        Destination(
          name: 'origin',
          location: '',
          lat: start.latitude,
          lng: start.longitude,
          visitHours: 0,
          category: '',
        ),
        stops[0],
      );
      final result = engine(stops, startingPoint: start)
          .optimizeAssignedItinerary([
            [],
            [0],
            [1],
          ]);

      expect(result.days, hasLength(3));
      expect(result.days[0].stopOrder, isEmpty);
      expect(result.days[1].stopOrder, [0]);
      expect(result.days[1].distanceKm, closeTo(expectedOriginLeg, 1e-9));
      expect(
        result.days[1].timeHours,
        closeTo(1 + expectedOriginLeg / 30, 1e-9),
      );
      expect(result.days[1].legDistances, hasLength(1));
      expect(
        result.days[1].legDistances.single,
        closeTo(expectedOriginLeg, 1e-9),
      );
      expect(result.days[2].stopOrder, [1]);
      expect(result.days[2].distanceKm, 0);
      expect(result.days.expand((day) => day.stopOrder).length, 2);
    });

    test('rejects an invalid starting coordinate', () {
      expect(
        () => engine(
          [destination('A')],
          startingPoint: const MogaStartingPoint(latitude: 91, longitude: 126),
        ),
        throwsArgumentError,
      );
    });

    test('origin travel is included when evaluating daily stop capacity', () {
      final result = engine(
        [destination('Long visit', hours: 8.9, lat: 7, lng: 126.2)],
        hours: 9,
        startingPoint: const MogaStartingPoint(latitude: 7, longitude: 125.7),
      ).optimizeDayTour();

      expect(result.stopOrder, [0]);
      expect(result.feasibility.isFeasible, isFalse);
      expect(result.paretoFront.single.fitness[1], 0);
    });

    test('RouteChromosome.copy safely copies unevaluated and evaluated fitness', () {
      final unevaluated = RouteChromosome([2, 1, 0]);
      final unevaluatedCopy = unevaluated.copy();
      expect(unevaluatedCopy.order, [2, 1, 0]);
      expect(unevaluatedCopy.isEvaluated, isFalse);

      unevaluated.fitness = [1.5, -2, 0.25];
      final evaluatedCopy = unevaluated.copy();
      expect(evaluatedCopy.isEvaluated, isTrue);
      expect(evaluatedCopy.fitness, [1.5, -2, 0.25]);
      unevaluated.fitness[0] = 99;
      expect(evaluatedCopy.fitness, [1.5, -2, 0.25]);
    });

    test('returns every selected index exactly once', () {
      final result = engine([
        destination('A'),
        destination('B', lng: 126.02),
        destination('C', lat: 7.02),
        destination('D', lng: 126.04),
      ]).optimizeDayTour();
      expect(result.stopOrder.toSet(), {0, 1, 2, 3});
      expect(result.stopOrder, hasLength(4));
      expect(result.stopOrder.toSet(), hasLength(result.stopOrder.length));
    });

    test('reports route over the daily time limit', () {
      final result = engine([
        destination('A', hours: 5),
        destination('B', hours: 5),
      ]).optimizeDayTour();
      expect(result.feasibility.isFeasible, isFalse);
      expect(result.feasibility.overByHours, greaterThan(0));
    });

    test('reports a single destination longer than the daily limit', () {
      final result = engine([destination('Long visit', hours: 10)]).optimizeDayTour();
      expect(result.stopOrder, [0]);
      expect(result.feasibility.isFeasible, isFalse);
      expect(result.feasibility.overByHours, 1);
    });

    test('preserves assigned days and optimizes only within each assignment', () {
      final result = engine([
        destination('A'),
        destination('B', lng: 126.01),
        destination('C', lat: 7.01),
        destination('D', lng: 126.02),
      ]).optimizeAssignedItinerary([
        [0, 2],
        [1, 3],
      ]);
      expect(result.days, hasLength(2));
      expect(result.days[0].stopOrder, hasLength(2));
      expect(result.days[1].stopOrder, hasLength(2));
      expect(result.days[0].stopOrder.toSet(), {0, 2});
      expect(result.days[1].stopOrder.toSet(), {1, 3});
      expect(result.days.expand((day) => day.stopOrder).toSet(), {0, 1, 2, 3});
      expect(result.days.every((day) => day.paretoFront.isNotEmpty), isTrue);
      expect(result.dayCountSatisfied, isTrue);
    });

    test('keeps requested day count and all stops when some days are infeasible', () {
      final result = engine([
        destination('A', hours: 10),
        destination('B', hours: 10),
        destination('C', hours: 10),
      ]).optimizeAssignedItinerary([
        [0, 1],
        [2],
      ]);
      expect(result.days, hasLength(2));
      expect(result.days.length, lessThanOrEqualTo(result.requestedDayCount));
      expect(result.days.expand((day) => day.stopOrder).toSet(), {0, 1, 2});
      expect(result.isFeasible, isFalse);
      expect(result.violations, isNotEmpty);
      expect(result.violations.every((v) => v.dayNumber <= 2), isTrue);
    });

    test('accumulates travel and visit time and identifies the exact violating stop', () {
      final destinations = [
        destination('A', hours: 4, lat: 7, lng: 126),
        destination('B', hours: 4, lat: 7.3, lng: 126.1),
      ];
      final result = engine(destinations).optimizeAssignedItinerary([
        [0, 1],
      ]);
      final day = result.days.single;
      final expectedTravel = roadEstimateKm(
            destinations[day.stopOrder[0]],
            destinations[day.stopOrder[1]],
          ) /
          30;
      final expectedTotal = 4 + expectedTravel + 4;
      final expectedOverrun = expectedTotal - 9;

      expect(day.timeHours, closeTo(expectedTotal, 1e-9));
      expect(day.feasibility.requiredHours, closeTo(expectedTotal, 1e-9));
      expect(day.feasibility.overByHours, closeTo(expectedOverrun, 1e-9));
      expect(result.violations, hasLength(1));
      expect(result.violations.single.dayNumber, 1);
      expect(result.violations.single.destinationIndex, day.stopOrder[1]);
      expect(result.violations.single.requiredHours, closeTo(expectedTotal, 1e-9));
      expect(result.violations.single.availableHours, 9);
      expect(result.violations.single.overByHours, closeTo(expectedOverrun, 1e-9));
    });

    test('reports an assigned empty day without moving other assignments', () {
      final result = engine([
        destination('A'),
        destination('B'),
      ]).optimizeAssignedItinerary([
        [0],
        [],
        [1],
      ]);
      expect(result.days, hasLength(3));
      expect(result.days[1].stopOrder, isEmpty);
      expect(result.days[2].stopOrder, [1]);
    });

    test('rejects invalid constructor inputs and assignments', () {
      expect(
        () => engine([destination('A')], daysPopulation: 0),
        throwsArgumentError,
      );
      expect(
        () => MogaEngine(destinations: [destination('A')], avgSpeedKmh: 0),
        throwsArgumentError,
      );
      expect(
        () => MogaEngine(destinations: [destination('A')], tourHours: double.infinity),
        throwsArgumentError,
      );
      expect(
        () => MogaEngine(destinations: [destination('A', hours: -1)]),
        throwsArgumentError,
      );
      expect(
        () => MogaEngine(destinations: [destination('A', lat: 91)]),
        throwsArgumentError,
      );
      expect(
        () => MogaEngine(destinations: [destination('A', lng: -181)]),
        throwsArgumentError,
      );
      expect(
        () => MogaEngine(destinations: [destination('A')], generations: -1),
        throwsArgumentError,
      );
      expect(
        () => MogaEngine(destinations: [destination('A')], crossoverRate: 1.1),
        throwsArgumentError,
      );
      expect(
        () => MogaEngine(destinations: [destination('A')], mutationRate: -0.1),
        throwsArgumentError,
      );
      expect(
        () => MogaEngine(destinations: [destination('A')], crossoverRate: double.nan),
        throwsArgumentError,
      );
      expect(
        () => engine([destination('A')]).optimizeItinerary(0),
        throwsArgumentError,
      );
      expect(
        () => engine([destination('A'), destination('B')])
            .optimizeAssignedItinerary([[0], [0]]),
        throwsArgumentError,
      );
    });

    test('is reproducible when separate engines use the same seed', () {
      final destinations = [
        destination('A', lng: 126.01),
        destination('B', lat: 7.03),
        destination('C', lng: 126.05),
        destination('D', lat: 7.04, lng: 126.02),
        destination('E', lng: 126.08),
      ];
      final first = engine(destinations).optimizeDayTour();
      final second = engine(destinations).optimizeDayTour();
      expect(second.stopOrder, first.stopOrder);
      expect(second.totalDistanceKm, first.totalDistanceKm);
      expect(
        second.paretoFront.map((candidate) => candidate.stopOrder),
        first.paretoFront.map((candidate) => candidate.stopOrder),
      );
      expect(
        second.paretoFront.map((candidate) => candidate.fitness),
        first.paretoFront.map((candidate) => candidate.fitness),
      );
    });

    test('Pareto-front candidates are mutually non-dominated', () {
      final result = engine([
        destination('A', lng: 126.01),
        destination('B', lat: 7.03),
        destination('C', lng: 126.05),
        destination('D', lat: 7.04, lng: 126.02),
        destination('E', lng: 126.08),
      ]).optimizeDayTour();

      bool dominates(List<double> a, List<double> b) {
        var strictlyBetter = false;
        for (var i = 0; i < a.length; i++) {
          if (a[i] > b[i]) return false;
          if (a[i] < b[i]) strictlyBetter = true;
        }
        return strictlyBetter;
      }

      for (var i = 0; i < result.paretoFront.length; i++) {
        for (var j = i + 1; j < result.paretoFront.length; j++) {
          expect(
            dominates(result.paretoFront[i].fitness, result.paretoFront[j].fitness),
            isFalse,
          );
          expect(
            dominates(result.paretoFront[j].fitness, result.paretoFront[i].fitness),
            isFalse,
          );
        }
      }
    });

    test('compatibility multi-day API never emits more than requested days', () {
      final result = engine([
        destination('A', hours: 10),
        destination('B', hours: 10),
        destination('C', hours: 10),
      ]).optimizeItinerary(2);
      expect(result.days.length, lessThanOrEqualTo(2));
      expect(result.requestedDayCount, 2);
      expect(result.days.expand((day) => day.stopOrder).toSet(), {0, 1, 2});
      expect(result.isFeasible, isFalse);
    });
  });
}

