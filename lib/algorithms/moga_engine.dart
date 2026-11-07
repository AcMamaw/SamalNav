import 'dart:math';

/// Represents a destination with coordinates and visit duration.
class Destination {
  final String name;
  final String location;
  final double lat;
  final double lng;
  final double visitHours;
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
  final List<int> order;
  List<double>? _fitness;
  List<double> get fitness {
    final value = _fitness;
    if (value == null) throw StateError('Chromosome fitness has not been evaluated.');
    return value;
  }
  set fitness(List<double> value) => _fitness = value;
  bool get isEvaluated => _fitness != null;
  int rank = 0;
  double crowdingDistance = 0.0;

  RouteChromosome(this.order);

  RouteChromosome copy() {
    final c = RouteChromosome(List<int>.from(order));
    final currentFitness = _fitness;
    if (currentFitness != null) {
      c.fitness = List<double>.from(currentFitness);
    }
    c.rank = rank;
    c.crowdingDistance = crowdingDistance;
    return c;
  }
}

class RouteFeasibility {
  final bool isFeasible;
  final double availableHours;
  final double requiredHours;
  final double overByHours;

  const RouteFeasibility({
    required this.isFeasible,
    required this.availableHours,
    required this.requiredHours,
    required this.overByHours,
  });
}

class DayViolation {
  final int dayNumber;
  final int destinationIndex;
  final double requiredHours;
  final double availableHours;
  final double overByHours;

  const DayViolation({
    required this.dayNumber,
    required this.destinationIndex,
    required this.requiredHours,
    required this.availableHours,
    required this.overByHours,
  });
}

class ParetoCandidate {
  final List<int> stopOrder;
  final List<double> fitness;

  const ParetoCandidate({required this.stopOrder, required this.fitness});
}

/// Route and objective values for the selected Pareto candidate.
class RouteResult {
  final List<int> stopOrder;
  final double totalDistanceKm;
  final double totalTimeHours;
  final List<double> legDistances;
  final List<double> legTravelMins;
  final RouteFeasibility feasibility;
  final List<ParetoCandidate> paretoFront;
  final String selectionPolicy;

  const RouteResult({
    required this.stopOrder,
    required this.totalDistanceKm,
    required this.totalTimeHours,
    required this.legDistances,
    required this.legTravelMins,
    required this.feasibility,
    required this.paretoFront,
    required this.selectionPolicy,
  });
}

class ItineraryResult {
  final List<DayPlan> days;
  final double totalDistanceKm;
  final int requestedDayCount;
  final bool dayCountSatisfied;
  final List<DayViolation> violations;

  const ItineraryResult({
    required this.days,
    required this.totalDistanceKm,
    required this.requestedDayCount,
    required this.dayCountSatisfied,
    required this.violations,
  });

  bool get isFeasible => dayCountSatisfied && violations.isEmpty;
}

class DayPlan {
  final int dayNumber;
  final List<int> stopOrder;
  final double distanceKm;
  final double timeHours;
  final List<double> legDistances;
  final List<double> legTravelMins;
  final RouteFeasibility feasibility;
  final List<ParetoCandidate> paretoFront;

  const DayPlan({
    required this.dayNumber,
    required this.stopOrder,
    required this.distanceKm,
    required this.timeHours,
    required this.legDistances,
    required this.legTravelMins,
    required this.feasibility,
    required this.paretoFront,
  });
}

/// NSGA-II style permutation optimizer. It returns a deterministic distance-
/// first representative of the first Pareto front and exposes that front's
/// objective vectors for callers that want to present trade-offs.
class MogaEngine {
  final List<Destination> destinations;
  final double tourHours;
  final double avgSpeedKmh;
  final int populationSize;
  final int generations;
  final double crossoverRate;
  final double mutationRate;
  final int? randomSeed;
  late final Random _rng = randomSeed == null ? Random() : Random(randomSeed);

  MogaEngine({
    required this.destinations,
    this.tourHours = 9.0,
    this.avgSpeedKmh = 30.0,
    this.populationSize = 50,
    this.generations = 100,
    this.crossoverRate = 0.8,
    this.mutationRate = 0.2,
    this.randomSeed,
  }) {
    _validateParameters();
    _validateDestinations(destinations);
  }

  void _validateParameters() {
    if (!tourHours.isFinite || tourHours <= 0) {
      throw ArgumentError.value(tourHours, 'tourHours', 'Must be finite and positive.');
    }
    if (!avgSpeedKmh.isFinite || avgSpeedKmh <= 0) {
      throw ArgumentError.value(avgSpeedKmh, 'avgSpeedKmh', 'Must be finite and positive.');
    }
    if (populationSize <= 0) {
      throw ArgumentError.value(populationSize, 'populationSize', 'Must be positive.');
    }
    if (generations < 0) {
      throw ArgumentError.value(generations, 'generations', 'Cannot be negative.');
    }
    if (!crossoverRate.isFinite || crossoverRate < 0 || crossoverRate > 1) {
      throw ArgumentError.value(crossoverRate, 'crossoverRate', 'Must be between 0 and 1.');
    }
    if (!mutationRate.isFinite || mutationRate < 0 || mutationRate > 1) {
      throw ArgumentError.value(mutationRate, 'mutationRate', 'Must be between 0 and 1.');
    }
  }

  static void _validateDestinations(List<Destination> values) {
    for (var i = 0; i < values.length; i++) {
      final d = values[i];
      if (!d.lat.isFinite || d.lat < -90 || d.lat > 90) {
        throw ArgumentError('Destination $i has invalid latitude: ${d.lat}.');
      }
      if (!d.lng.isFinite || d.lng < -180 || d.lng > 180) {
        throw ArgumentError('Destination $i has invalid longitude: ${d.lng}.');
      }
      if (!d.visitHours.isFinite || d.visitHours < 0) {
        throw ArgumentError('Destination $i has invalid visit duration: ${d.visitHours}.');
      }
    }
  }

  void _validateOrder(List<int> order) {
    if (order.toSet().length != order.length ||
        order.any((index) => index < 0 || index >= destinations.length)) {
      throw ArgumentError('Each assigned destination index must be valid and unique.');
    }
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double degrees) => degrees * pi / 180;

  late final List<List<double>> _distMatrix = _buildDistMatrix();

  List<List<double>> _buildDistMatrix() {
    final n = destinations.length;
    final matrix = List.generate(n, (_) => List.filled(n, 0.0));
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final d = _haversine(
          destinations[i].lat,
          destinations[i].lng,
          destinations[j].lat,
          destinations[j].lng,
        ) * 1.3;
        matrix[i][j] = d;
        matrix[j][i] = d;
      }
    }
    return matrix;
  }

  List<double> _fitnessForOrder(List<int> order) {
    if (order.isEmpty) return [0, 0, 0];
    var totalDistance = 0.0;
    var timeUsed = 0.0;
    var attractionsFit = 0;
    final stopTimes = <double>[];
    for (var i = 0; i < order.length; i++) {
      final travelTime = i == 0 ? 0.0 : _distMatrix[order[i - 1]][order[i]] / avgSpeedKmh;
      final stopTime = travelTime + destinations[order[i]].visitHours;
      if (i > 0) totalDistance += _distMatrix[order[i - 1]][order[i]];
      timeUsed += stopTime;
      if (timeUsed <= tourHours) attractionsFit++;
      stopTimes.add(stopTime);
    }
    final mean = timeUsed / order.length;
    final variance = stopTimes.fold<double>(
          0,
          (sum, value) => sum + (value - mean) * (value - mean),
        ) /
        order.length;
    return [totalDistance, -attractionsFit.toDouble(), variance];
  }

  void _evaluate(RouteChromosome chromosome) {
    chromosome.fitness = _fitnessForOrder(chromosome.order);
  }

  bool _dominates(RouteChromosome a, RouteChromosome b) {
    var strictlyBetter = false;
    for (var i = 0; i < a.fitness.length; i++) {
      if (a.fitness[i] > b.fitness[i]) return false;
      if (a.fitness[i] < b.fitness[i]) strictlyBetter = true;
    }
    return strictlyBetter;
  }

  List<List<int>> _nonDominatedSort(List<RouteChromosome> population) {
    final count = population.length;
    final dominationCount = List.filled(count, 0);
    final dominated = List.generate(count, (_) => <int>[]);
    final fronts = <List<int>>[[]];
    for (var i = 0; i < count; i++) {
      for (var j = i + 1; j < count; j++) {
        if (_dominates(population[i], population[j])) {
          dominated[i].add(j);
          dominationCount[j]++;
        } else if (_dominates(population[j], population[i])) {
          dominated[j].add(i);
          dominationCount[i]++;
        }
      }
      if (dominationCount[i] == 0) {
        population[i].rank = 0;
        fronts[0].add(i);
      }
    }
    var frontIndex = 0;
    while (fronts[frontIndex].isNotEmpty) {
      final nextFront = <int>[];
      for (final i in fronts[frontIndex]) {
        for (final j in dominated[i]) {
          dominationCount[j]--;
          if (dominationCount[j] == 0) {
            population[j].rank = frontIndex + 1;
            nextFront.add(j);
          }
        }
      }
      frontIndex++;
      fronts.add(nextFront);
    }
    return fronts;
  }

  void _crowdingDistance(List<RouteChromosome> population, List<int> front) {
    if (front.length <= 2) {
      for (final i in front) {
        population[i].crowdingDistance = double.infinity;
      }
      return;
    }
    for (final i in front) {
      population[i].crowdingDistance = 0;
    }
    final objectiveCount = population[front.first].fitness.length;
    for (var objective = 0; objective < objectiveCount; objective++) {
      final sorted = List<int>.from(front)
        ..sort((a, b) => population[a].fitness[objective].compareTo(population[b].fitness[objective]));
      population[sorted.first].crowdingDistance = double.infinity;
      population[sorted.last].crowdingDistance = double.infinity;
      final minValue = population[sorted.first].fitness[objective];
      final range = population[sorted.last].fitness[objective] - minValue;
      if (range == 0) continue;
      for (var i = 1; i < sorted.length - 1; i++) {
        population[sorted[i]].crowdingDistance +=
            (population[sorted[i + 1]].fitness[objective] -
                population[sorted[i - 1]].fitness[objective]) /
            range;
      }
    }
  }

  RouteChromosome _tournament(List<RouteChromosome> population) {
    final a = population[_rng.nextInt(population.length)];
    final b = population[_rng.nextInt(population.length)];
    if (a.rank < b.rank) return a;
    if (b.rank < a.rank) return b;
    return a.crowdingDistance >= b.crowdingDistance ? a : b;
  }

  RouteChromosome _crossover(RouteChromosome p1, RouteChromosome p2) {
    final n = p1.order.length;
    if (n <= 2) return p1.copy();
    final start = _rng.nextInt(n);
    final end = start + _rng.nextInt(n - start);
    final child = List.filled(n, -1);
    for (var i = start; i <= end; i++) {
      child[i] = p1.order[i];
    }
    var position = (end + 1) % n;
    for (var i = 0; i < n; i++) {
      final gene = p2.order[(end + 1 + i) % n];
      if (!child.contains(gene)) {
        child[position] = gene;
        position = (position + 1) % n;
      }
    }
    return RouteChromosome(child);
  }

  void _mutate(RouteChromosome chromosome) {
    final n = chromosome.order.length;
    if (n <= 1) return;
    final i = _rng.nextInt(n);
    var j = _rng.nextInt(n - 1);
    if (j >= i) j++;
    final temp = chromosome.order[i];
    chromosome.order[i] = chromosome.order[j];
    chromosome.order[j] = temp;
  }

  List<RouteChromosome> _evolve(List<int> assignedIndices) {
    _validateOrder(assignedIndices);
    if (assignedIndices.length <= 1) {
      final only = RouteChromosome(List<int>.from(assignedIndices));
      _evaluate(only);
      return [only];
    }
    var population = List.generate(populationSize, (_) {
      final order = List<int>.from(assignedIndices)..shuffle(_rng);
      final chromosome = RouteChromosome(order);
      _evaluate(chromosome);
      return chromosome;
    });
    for (var generation = 0; generation < generations; generation++) {
      for (final front in _nonDominatedSort(population)) {
        if (front.isNotEmpty) _crowdingDistance(population, front);
      }
      final offspring = <RouteChromosome>[];
      while (offspring.length < populationSize) {
        final p1 = _tournament(population);
        final p2 = _tournament(population);
        final child = _rng.nextDouble() < crossoverRate ? _crossover(p1, p2) : p1.copy();
        if (_rng.nextDouble() < mutationRate) _mutate(child);
        _evaluate(child);
        offspring.add(child);
      }
      final combined = [...population, ...offspring];
      final fronts = _nonDominatedSort(combined);
      final next = <RouteChromosome>[];
      for (final front in fronts) {
        if (front.isEmpty) continue;
        _crowdingDistance(combined, front);
        if (next.length + front.length <= populationSize) {
          next.addAll(front.map((i) => combined[i]));
        } else {
          final sorted = List<int>.from(front)
            ..sort((a, b) => combined[b].crowdingDistance.compareTo(combined[a].crowdingDistance));
          for (final index in sorted) {
            if (next.length == populationSize) break;
            next.add(combined[index]);
          }
          break;
        }
      }
      population = next;
    }
    final fronts = _nonDominatedSort(population);
    for (final front in fronts) {
      if (front.isNotEmpty) _crowdingDistance(population, front);
    }
    return fronts.first.map((index) => population[index]).toList();
  }

  /// Selects the minimum-distance member of the first Pareto front.
  /// This is a presentation policy, not a claim that it is best on every
  /// objective. The full first-front objective vectors are returned as well.
  RouteResult optimizeDayTour() => optimizeAssignedDay(List.generate(destinations.length, (i) => i));

  RouteResult optimizeAssignedDay(List<int> assignedIndices) {
    _validateOrder(assignedIndices);
    final front = _evolve(assignedIndices);
    RouteChromosome selected = front.first;
    for (final candidate in front.skip(1)) {
      if (candidate.fitness[0] < selected.fitness[0]) selected = candidate;
    }
    return _buildResult(
      selected.order,
      front
          .map((candidate) => ParetoCandidate(
                stopOrder: List<int>.from(candidate.order),
                fitness: List<double>.from(candidate.fitness),
              ))
          .toList(),
    );
  }

  RouteResult _buildResult(List<int> order, List<ParetoCandidate> paretoFront) {
    var totalDistance = 0.0;
    var totalTime = 0.0;
    final legDistances = <double>[];
    final legMinutes = <double>[];
    for (var i = 0; i < order.length; i++) {
      final travelHours = i == 0 ? 0.0 : _distMatrix[order[i - 1]][order[i]] / avgSpeedKmh;
      if (i > 0) {
        final distance = _distMatrix[order[i - 1]][order[i]];
        totalDistance += distance;
        legDistances.add(distance);
        legMinutes.add(travelHours * 60);
      }
      totalTime += travelHours + destinations[order[i]].visitHours;
    }
    final overBy = max(0.0, totalTime - tourHours);
    return RouteResult(
      stopOrder: List<int>.from(order),
      totalDistanceKm: totalDistance,
      totalTimeHours: totalTime,
      legDistances: legDistances,
      legTravelMins: legMinutes,
      feasibility: RouteFeasibility(
        isFeasible: overBy <= 1e-9,
        availableHours: tourHours,
        requiredHours: totalTime,
        overByHours: overBy,
      ),
      paretoFront: paretoFront,
      selectionPolicy: 'Minimum total distance among first-front candidates.',
    );
  }

  /// Optimizes each preassigned day's order independently. Destination indexes
  /// remain global indexes into [destinations]. Every assignment is retained.
  ItineraryResult optimizeAssignedItinerary(List<List<int>> assignedDays) {
    if (assignedDays.isEmpty) {
      throw ArgumentError.value(assignedDays, 'assignedDays', 'Must contain at least one day.');
    }
    final seen = <int>{};
    for (final day in assignedDays) {
      _validateOrder(day);
      for (final index in day) {
        if (!seen.add(index)) {
          throw ArgumentError('A destination cannot be assigned to more than one day.');
        }
      }
    }
    final days = <DayPlan>[];
    final violations = <DayViolation>[];
    for (var i = 0; i < assignedDays.length; i++) {
      final result = optimizeAssignedDay(assignedDays[i]);
      days.add(DayPlan(
        dayNumber: i + 1,
        stopOrder: result.stopOrder,
        distanceKm: result.totalDistanceKm,
        timeHours: result.totalTimeHours,
        legDistances: result.legDistances,
        legTravelMins: result.legTravelMins,
        feasibility: result.feasibility,
        paretoFront: result.paretoFront,
      ));
      var elapsed = 0.0;
      for (var stop = 0; stop < result.stopOrder.length; stop++) {
        if (stop > 0) {
          elapsed += _distMatrix[result.stopOrder[stop - 1]][result.stopOrder[stop]] / avgSpeedKmh;
        }
        elapsed += destinations[result.stopOrder[stop]].visitHours;
        if (elapsed > tourHours + 1e-9) {
          violations.add(DayViolation(
            dayNumber: i + 1,
            destinationIndex: result.stopOrder[stop],
            requiredHours: elapsed,
            availableHours: tourHours,
            overByHours: elapsed - tourHours,
          ));
        }
      }
    }
    return ItineraryResult(
      days: days,
      totalDistanceKm: days.fold(0.0, (sum, day) => sum + day.distanceKm),
      requestedDayCount: assignedDays.length,
      dayCountSatisfied: days.length == assignedDays.length,
      violations: violations,
    );
  }

  /// Compatibility helper: splits the full selected set into at most the
  /// requested number of sequential days, retaining any infeasible stops in
  /// the final requested day and reporting their overrun.
  ItineraryResult optimizeItinerary(int numberOfDays) {
    if (numberOfDays <= 0) {
      throw ArgumentError.value(numberOfDays, 'numberOfDays', 'Must be positive.');
    }
    if (destinations.isEmpty) {
      return ItineraryResult(
        days: [],
        totalDistanceKm: 0,
        requestedDayCount: numberOfDays,
        dayCountSatisfied: true,
        violations: const [],
      );
    }
    final route = optimizeDayTour();
    final assignments = List.generate(numberOfDays, (_) => <int>[]);
    var day = 0;
    var dayTime = 0.0;
    for (var i = 0; i < route.stopOrder.length; i++) {
      final index = route.stopOrder[i];
      final travel = assignments[day].isEmpty
          ? 0.0
          : _distMatrix[assignments[day].last][index] / avgSpeedKmh;
      final required = travel + destinations[index].visitHours;
      if (dayTime + required > tourHours && assignments[day].isNotEmpty && day < numberOfDays - 1) {
        day++;
        dayTime = 0;
      }
      final actualTravel = assignments[day].isEmpty
          ? 0.0
          : _distMatrix[assignments[day].last][index] / avgSpeedKmh;
      assignments[day].add(index);
      dayTime += actualTravel + destinations[index].visitHours;
    }
    final result = optimizeAssignedItinerary(assignments.where((d) => d.isNotEmpty).toList());
    return ItineraryResult(
      days: result.days,
      totalDistanceKm: result.totalDistanceKm,
      requestedDayCount: numberOfDays,
      dayCountSatisfied: result.days.length <= numberOfDays,
      violations: result.violations,
    );
  }
}
