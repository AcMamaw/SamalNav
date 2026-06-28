import 'dart:math';

/// Represents a destination with coordinates and visit duration.
class Destination {
  final String name;
  final String location;
  final double lat;
  final double lng;
  final double visitHours; // estimated hours to spend
  final String category;

  const Destination({
    required this.name,
    required this.location,
    required this.lat,
    required this.lng,
    required this.visitHours,
    required this.category,
  });
}

/// A single route solution (chromosome) in the MOGA population.
class RouteChromosome {
  final List<int> order; // indices into the destination list
  late final List<double> fitness; // [distance, -attractionsInTime, timeVariance]
  int rank = 0;
  double crowdingDistance = 0.0;

  RouteChromosome(this.order);

  RouteChromosome copy() {
    final c = RouteChromosome(List<int>.from(order));
    c.rank = rank;
    c.crowdingDistance = crowdingDistance;
    return c;
  }
}

/// Result of the MOGA optimization.
class RouteResult {
  final List<int> stopOrder;         // indices into the destination list
  final double totalDistanceKm;
  final double totalTimeHours;       // travel + visit time
  final List<double> legDistances;   // distance between consecutive stops
  final List<double> legTravelMins;  // travel minutes between consecutive stops

  const RouteResult({
    required this.stopOrder,
    required this.totalDistanceKm,
    required this.totalTimeHours,
    required this.legDistances,
    required this.legTravelMins,
  });
}

/// Multi-day itinerary result.
class ItineraryResult {
  final List<DayPlan> days;
  final double totalDistanceKm;

  const ItineraryResult({required this.days, required this.totalDistanceKm});
}

class DayPlan {
  final int dayNumber;
  final List<int> stopOrder;
  final double distanceKm;
  final double timeHours;
  final List<double> legDistances;
  final List<double> legTravelMins;

  const DayPlan({
    required this.dayNumber,
    required this.stopOrder,
    required this.distanceKm,
    required this.timeHours,
    required this.legDistances,
    required this.legTravelMins,
  });
}

// ═══════════════════════════════════════════════════════════════════
//  MOGA ENGINE
// ═══════════════════════════════════════════════════════════════════

class MogaEngine {
  final List<Destination> destinations;
  final double tourHours;        // available hours per day (default 9)
  final double avgSpeedKmh;      // average speed on island roads
  final int populationSize;
  final int generations;
  final double crossoverRate;
  final double mutationRate;
  final Random _rng = Random();

  MogaEngine({
    required this.destinations,
    this.tourHours = 9.0,
    this.avgSpeedKmh = 30.0,
    this.populationSize = 50,
    this.generations = 100,
    this.crossoverRate = 0.8,
    this.mutationRate = 0.2,
  });

  // ── Haversine distance (km) ───────────────────────────────────
  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;

  // ── Distance matrix ───────────────────────────────────────────
  late final List<List<double>> _distMatrix = _buildDistMatrix();

  List<List<double>> _buildDistMatrix() {
    final n = destinations.length;
    final matrix = List.generate(n, (_) => List.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final d = _haversine(
          destinations[i].lat, destinations[i].lng,
          destinations[j].lat, destinations[j].lng,
        );
        // Multiply by 1.3 to approximate road distance from straight-line
        matrix[i][j] = d * 1.3;
        matrix[j][i] = d * 1.3;
      }
    }
    return matrix;
  }

  // ── Fitness evaluation ────────────────────────────────────────
  void _evaluate(RouteChromosome chrome) {
    final order = chrome.order;
    if (order.isEmpty) {
      chrome.fitness = [0, 0, 0];
      return;
    }

    // f1: Total travel distance
    double totalDist = 0;
    for (int i = 0; i < order.length - 1; i++) {
      totalDist += _distMatrix[order[i]][order[i + 1]];
    }

    // f2: Number of attractions that fit within time budget (negative = maximize)
    double timeUsed = 0;
    int attractionsFit = 0;
    for (int i = 0; i < order.length; i++) {
      double travelTime = 0;
      if (i > 0) {
        travelTime = _distMatrix[order[i - 1]][order[i]] / avgSpeedKmh;
      }
      timeUsed += travelTime + destinations[order[i]].visitHours;
      if (timeUsed <= tourHours) {
        attractionsFit++;
      }
    }

    // f3: Time variance (how balanced the time is across stops)
    final avgTime = timeUsed / max(order.length, 1);
    double variance = 0;
    // ignore: unused_local_variable
    double runningTime = 0;
    for (int i = 0; i < order.length; i++) {
      double travelTime = 0;
      if (i > 0) {
        travelTime = _distMatrix[order[i - 1]][order[i]] / avgSpeedKmh;
      }
      final stopTime = travelTime + destinations[order[i]].visitHours;
      runningTime += stopTime;
      variance += (stopTime - avgTime) * (stopTime - avgTime);
    }
    variance /= max(order.length, 1);

    chrome.fitness = [totalDist, -attractionsFit.toDouble(), variance];
  }

  // ── Pareto dominance ──────────────────────────────────────────
  bool _dominates(RouteChromosome a, RouteChromosome b) {
    bool atLeastOneBetter = false;
    for (int i = 0; i < a.fitness.length; i++) {
      if (a.fitness[i] > b.fitness[i]) return false; // worse in one objective
      if (a.fitness[i] < b.fitness[i]) atLeastOneBetter = true;
    }
    return atLeastOneBetter;
  }

  // ── Non-dominated sorting ─────────────────────────────────────
  List<List<int>> _nonDominatedSort(List<RouteChromosome> pop) {
    final n = pop.length;
    final dominationCount = List.filled(n, 0);
    final dominatedSet = List.generate(n, (_) => <int>[]);
    final fronts = <List<int>>[[]];

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        if (_dominates(pop[i], pop[j])) {
          dominatedSet[i].add(j);
          dominationCount[j]++;
        } else if (_dominates(pop[j], pop[i])) {
          dominatedSet[j].add(i);
          dominationCount[i]++;
        }
      }
      if (dominationCount[i] == 0) {
        pop[i].rank = 0;
        fronts[0].add(i);
      }
    }

    int frontIndex = 0;
    while (fronts[frontIndex].isNotEmpty) {
      final nextFront = <int>[];
      for (final i in fronts[frontIndex]) {
        for (final j in dominatedSet[i]) {
          dominationCount[j]--;
          if (dominationCount[j] == 0) {
            pop[j].rank = frontIndex + 1;
            nextFront.add(j);
          }
        }
      }
      frontIndex++;
      fronts.add(nextFront);
    }

    return fronts;
  }

  // ── Crowding distance ─────────────────────────────────────────
  void _crowdingDistance(List<RouteChromosome> pop, List<int> front) {
    final n = front.length;
    if (n <= 2) {
      for (final i in front) {
        pop[i].crowdingDistance = double.infinity;
      }
      return;
    }

    for (final i in front) {
      pop[i].crowdingDistance = 0;
    }

    final numObjectives = pop[front[0]].fitness.length;
    for (int m = 0; m < numObjectives; m++) {
      final sorted = List<int>.from(front)
        ..sort((a, b) => pop[a].fitness[m].compareTo(pop[b].fitness[m]));

      pop[sorted[0]].crowdingDistance = double.infinity;
      pop[sorted[n - 1]].crowdingDistance = double.infinity;

      final fMin = pop[sorted[0]].fitness[m];
      final fMax = pop[sorted[n - 1]].fitness[m];
      final range = fMax - fMin;
      if (range == 0) continue;

      for (int i = 1; i < n - 1; i++) {
        pop[sorted[i]].crowdingDistance +=
            (pop[sorted[i + 1]].fitness[m] - pop[sorted[i - 1]].fitness[m]) / range;
      }
    }
  }

  // ── Tournament selection ──────────────────────────────────────
  RouteChromosome _tournament(List<RouteChromosome> pop) {
    final a = pop[_rng.nextInt(pop.length)];
    final b = pop[_rng.nextInt(pop.length)];
    if (a.rank < b.rank) return a;
    if (b.rank < a.rank) return b;
    return a.crowdingDistance > b.crowdingDistance ? a : b;
  }

  // ── Order crossover (OX) ──────────────────────────────────────
  RouteChromosome _crossover(RouteChromosome p1, RouteChromosome p2) {
    final n = p1.order.length;
    if (n <= 2) return p1.copy();

    final start = _rng.nextInt(n);
    final end = start + _rng.nextInt(n - start);

    final child = List.filled(n, -1);
    // Copy segment from p1
    for (int i = start; i <= end && i < n; i++) {
      child[i] = p1.order[i];
    }

    // Fill rest from p2 in order
    int pos = (end + 1) % n;
    for (int i = 0; i < n; i++) {
      final gene = p2.order[(end + 1 + i) % n];
      if (!child.contains(gene)) {
        child[pos] = gene;
        pos = (pos + 1) % n;
      }
    }

    return RouteChromosome(child);
  }

  // ── Swap mutation ─────────────────────────────────────────────
  void _mutate(RouteChromosome chrome) {
    final n = chrome.order.length;
    if (n <= 1) return;
    final i = _rng.nextInt(n);
    int j = _rng.nextInt(n);
    while (j == i) {
      j = _rng.nextInt(n);
    }
    final temp = chrome.order[i];
    chrome.order[i] = chrome.order[j];
    chrome.order[j] = temp;
  }

  // ── Run MOGA for single day ───────────────────────────────────
  RouteResult optimizeDayTour() {
    final n = destinations.length;
    if (n == 0) {
      return const RouteResult(
        stopOrder: [], totalDistanceKm: 0, totalTimeHours: 0,
        legDistances: [], legTravelMins: [],
      );
    }
    if (n == 1) {
      return RouteResult(
        stopOrder: [0], totalDistanceKm: 0, totalTimeHours: destinations[0].visitHours,
        legDistances: [], legTravelMins: [],
      );
    }

    // Initialize population
    var population = List.generate(populationSize, (_) {
      final order = List.generate(n, (i) => i)..shuffle(_rng);
      return RouteChromosome(order);
    });

    for (final c in population) {
      _evaluate(c);
    }

    // Evolution loop
    for (int gen = 0; gen < generations; gen++) {
      final offspring = <RouteChromosome>[];

      while (offspring.length < populationSize) {
        final p1 = _tournament(population);
        final p2 = _tournament(population);

        RouteChromosome child;
        if (_rng.nextDouble() < crossoverRate) {
          child = _crossover(p1, p2);
        } else {
          child = p1.copy();
        }

        if (_rng.nextDouble() < mutationRate) {
          _mutate(child);
        }

        _evaluate(child);
        offspring.add(child);
      }

      // Combine parent + offspring
      final combined = [...population, ...offspring];
      final fronts = _nonDominatedSort(combined);

      // Select next generation
      final nextPop = <RouteChromosome>[];
      for (final front in fronts) {
        if (front.isEmpty) continue;
        _crowdingDistance(combined, front);
        if (nextPop.length + front.length <= populationSize) {
          for (final i in front) {
            nextPop.add(combined[i]);
          }
        } else {
          final sorted = List<int>.from(front)
            ..sort((a, b) => combined[b].crowdingDistance.compareTo(combined[a].crowdingDistance));
          for (final i in sorted) {
            if (nextPop.length >= populationSize) break;
            nextPop.add(combined[i]);
          }
          break;
        }
      }

      population = nextPop;
    }

    // Pick best from front 0 (lowest total distance)
    final best = population.where((c) => c.rank == 0).reduce(
      (a, b) => a.fitness[0] < b.fitness[0] ? a : b,
    );

    return _buildResult(best.order);
  }

  RouteResult _buildResult(List<int> order) {
    double totalDist = 0;
    final legDists = <double>[];
    final legMins = <double>[];

    for (int i = 0; i < order.length - 1; i++) {
      final d = _distMatrix[order[i]][order[i + 1]];
      totalDist += d;
      legDists.add(d);
      legMins.add((d / avgSpeedKmh) * 60);
    }

    double totalTime = 0;
    for (int i = 0; i < order.length; i++) {
      if (i > 0) totalTime += _distMatrix[order[i - 1]][order[i]] / avgSpeedKmh;
      totalTime += destinations[order[i]].visitHours;
    }

    return RouteResult(
      stopOrder: order,
      totalDistanceKm: totalDist,
      totalTimeHours: totalTime,
      legDistances: legDists,
      legTravelMins: legMins,
    );
  }

  // ── Run MOGA for multi-day itinerary ──────────────────────────
  ItineraryResult optimizeItinerary(int numberOfDays) {
    // First optimize the overall order
    final fullRoute = optimizeDayTour();

    // Then split into days based on time budget
    final days = <DayPlan>[];
    int dayNum = 1;
    int startIdx = 0;

    while (startIdx < fullRoute.stopOrder.length && dayNum <= numberOfDays) {
      double dayTime = 0;
      int endIdx = startIdx;

      for (int i = startIdx; i < fullRoute.stopOrder.length; i++) {
        final destIdx = fullRoute.stopOrder[i];
        double travelTime = 0;
        if (i > startIdx) {
          travelTime = _distMatrix[fullRoute.stopOrder[i - 1]][destIdx] / avgSpeedKmh;
        }
        final totalForStop = travelTime + destinations[destIdx].visitHours;

        if (dayTime + totalForStop > tourHours && i > startIdx) break;
        dayTime += totalForStop;
        endIdx = i + 1;
      }

      if (endIdx > startIdx) {
        final dayOrder = fullRoute.stopOrder.sublist(startIdx, endIdx);
        final legDists = <double>[];
        final legMins = <double>[];
        double dayDist = 0;

        for (int i = 0; i < dayOrder.length - 1; i++) {
          final d = _distMatrix[dayOrder[i]][dayOrder[i + 1]];
          dayDist += d;
          legDists.add(d);
          legMins.add((d / avgSpeedKmh) * 60);
        }

        days.add(DayPlan(
          dayNumber: dayNum,
          stopOrder: dayOrder,
          distanceKm: dayDist,
          timeHours: dayTime,
          legDistances: legDists,
          legTravelMins: legMins,
        ));
      }

      startIdx = endIdx;
      dayNum++;
    }

    // If there are remaining stops and we still have days, add them
    if (startIdx < fullRoute.stopOrder.length) {
      final remaining = fullRoute.stopOrder.sublist(startIdx);
      final legDists = <double>[];
      final legMins = <double>[];
      double remDist = 0;
      double remTime = 0;

      for (int i = 0; i < remaining.length; i++) {
        if (i > 0) {
          final d = _distMatrix[remaining[i - 1]][remaining[i]];
          remDist += d;
          legDists.add(d);
          legMins.add((d / avgSpeedKmh) * 60);
          remTime += d / avgSpeedKmh;
        }
        remTime += destinations[remaining[i]].visitHours;
      }

      days.add(DayPlan(
        dayNumber: dayNum,
        stopOrder: remaining,
        distanceKm: remDist,
        timeHours: remTime,
        legDistances: legDists,
        legTravelMins: legMins,
      ));
    }

    final totalDist = days.fold(0.0, (sum, d) => sum + d.distanceKm);

    return ItineraryResult(days: days, totalDistanceKm: totalDist);
  }
}
