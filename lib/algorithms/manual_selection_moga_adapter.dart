import '../models/destination_record.dart';
import '../models/itinerary_draft.dart';
import 'moga_engine.dart' as moga;

/// Carries the current planner's MO-GA defaults into the adapter. The speed
/// value matches PlanPage's existing setting; this is still a straight-line
/// approximation, not a road-route estimate.
class ManualMogaConfiguration {
  final double averageSpeedKmh;
  final int populationSize;
  final int generations;
  final double crossoverRate;
  final double mutationRate;
  final int? randomSeed;

  const ManualMogaConfiguration({
    this.averageSpeedKmh = 30,
    this.populationSize = 50,
    this.generations = 100,
    this.crossoverRate = 0.8,
    this.mutationRate = 0.2,
    this.randomSeed,
  });
}

class DraftRouteParetoCandidate {
  final List<String> destinationIds;
  final List<double> objectives;

  DraftRouteParetoCandidate({
    required List<String> destinationIds,
    required List<double> objectives,
  }) : destinationIds = List.unmodifiable(destinationIds),
       objectives = List.unmodifiable(objectives);
}

class DraftRouteResult {
  final List<String> destinationIdsInRouteOrder;
  final double totalDistanceKm;
  final double totalTimeHours;
  final List<double> legDistancesKm;
  final List<double> legTravelMinutes;
  final moga.RouteFeasibility feasibility;
  final List<DraftRouteParetoCandidate> paretoFront;
  final String selectionPolicy;

  DraftRouteResult({
    required List<String> destinationIdsInRouteOrder,
    required this.totalDistanceKm,
    required this.totalTimeHours,
    required List<double> legDistancesKm,
    required List<double> legTravelMinutes,
    required this.feasibility,
    required List<DraftRouteParetoCandidate> paretoFront,
    required this.selectionPolicy,
  }) : destinationIdsInRouteOrder = List.unmodifiable(
         destinationIdsInRouteOrder,
       ),
       legDistancesKm = List.unmodifiable(legDistancesKm),
       legTravelMinutes = List.unmodifiable(legTravelMinutes),
       paretoFront = List.unmodifiable(paretoFront);
}

class DraftDayViolation {
  final int dayNumber;
  final String destinationId;
  final double requiredHours;
  final double availableHours;
  final double overByHours;

  const DraftDayViolation({
    required this.dayNumber,
    required this.destinationId,
    required this.requiredHours,
    required this.availableHours,
    required this.overByHours,
  });
}

class DraftDayPlan {
  final int dayNumber;
  final List<String> destinationIdsInRouteOrder;
  final double distanceKm;
  final double timeHours;
  final List<double> legDistancesKm;
  final List<double> legTravelMinutes;
  final moga.RouteFeasibility feasibility;
  final List<DraftRouteParetoCandidate> paretoFront;

  DraftDayPlan({
    required this.dayNumber,
    required List<String> destinationIdsInRouteOrder,
    required this.distanceKm,
    required this.timeHours,
    required List<double> legDistancesKm,
    required List<double> legTravelMinutes,
    required this.feasibility,
    required List<DraftRouteParetoCandidate> paretoFront,
  }) : destinationIdsInRouteOrder = List.unmodifiable(
         destinationIdsInRouteOrder,
       ),
       legDistancesKm = List.unmodifiable(legDistancesKm),
       legTravelMinutes = List.unmodifiable(legTravelMinutes),
       paretoFront = List.unmodifiable(paretoFront);
}

class DraftItineraryResult {
  final List<DraftDayPlan> days;
  final double totalDistanceKm;
  final int requestedDayCount;
  final bool dayCountSatisfied;
  final List<DraftDayViolation> violations;

  DraftItineraryResult({
    required List<DraftDayPlan> days,
    required this.totalDistanceKm,
    required this.requestedDayCount,
    required this.dayCountSatisfied,
    required List<DraftDayViolation> violations,
  }) : days = List.unmodifiable(days),
       violations = List.unmodifiable(violations);

  bool get isFeasible => dayCountSatisfied && violations.isEmpty;
}

class ManualMogaResult implements DraftOptimizationResult {
  final String draftId;
  final List<String> inputDestinationIdsInSelectionOrder;
  final DraftRouteResult? oneDay;
  final DraftItineraryResult? multiDay;

  ManualMogaResult({
    required this.draftId,
    required List<String> inputDestinationIdsInSelectionOrder,
    this.oneDay,
    this.multiDay,
  }) : inputDestinationIdsInSelectionOrder = List.unmodifiable(
         inputDestinationIdsInSelectionOrder,
       );
}

class DraftValidationException implements Exception {
  final List<String> errors;

  DraftValidationException(Iterable<String> errors)
    : errors = List.unmodifiable(errors);

  @override
  String toString() => 'Draft validation failed: ${errors.join(' ')}';
}

class DraftOptimizationException implements Exception {
  final String message;

  const DraftOptimizationException(this.message);

  @override
  String toString() => 'Draft optimization failed: $message';
}

/// Pure conversion boundary from reviewed drafts to index-based MO-GA.
/// The engine and its objective definitions are shared across planning flows.
class ManualSelectionMogaAdapter {
  const ManualSelectionMogaAdapter();

  ManualMogaResult optimize(
    ItineraryDraft draft, {
    ManualMogaConfiguration configuration = const ManualMogaConfiguration(),
  }) {
    final validationErrors = _validate(draft, configuration);
    if (validationErrors.isNotEmpty) {
      throw DraftValidationException(validationErrors);
    }

    final selected = draft.stops.where((stop) => stop.isIncluded).toList()
      ..sort((a, b) => a.selectionOrder.compareTo(b.selectionOrder));
    final inputIds = selected.map((stop) => stop.destinationId).toList();
    final idToIndex = <String, int>{
      for (var index = 0; index < selected.length; index++)
        selected[index].destinationId: index,
    };
    final engineDestinations = selected.map((stop) {
      final destination = stop.destination;
      return moga.Destination(
        name: destination.name,
        location: destination.location,
        lat: destination.latitude,
        lng: destination.longitude,
        visitHours: destination.visitDurationMinutes / 60,
        category: destination.category,
      );
    }).toList();

    try {
      final engine = moga.MogaEngine(
        destinations: engineDestinations,
        tourHours: draft.trip.availableHoursPerDay.toDouble(),
        avgSpeedKmh: configuration.averageSpeedKmh,
        populationSize: configuration.populationSize,
        generations: configuration.generations,
        crossoverRate: configuration.crossoverRate,
        mutationRate: configuration.mutationRate,
        randomSeed: configuration.randomSeed,
        startingPoint: draft.trip.origin == null
            ? null
            : moga.MogaStartingPoint(
                latitude: draft.trip.origin!.latitude,
                longitude: draft.trip.origin!.longitude,
              ),
      );

      if (draft.trip.durationDays == 1) {
        final route = engine.optimizeDayTour();
        return ManualMogaResult(
          draftId: draft.id,
          inputDestinationIdsInSelectionOrder: inputIds,
          oneDay: _mapRoute(route, inputIds),
        );
      }

      final assignedDays = List.generate(
        draft.trip.durationDays,
        (_) => <int>[],
      );
      for (final stop in selected) {
        final day = stop.assignedDay!;
        assignedDays[day - 1].add(idToIndex[stop.destinationId]!);
      }
      final itinerary = engine.optimizeAssignedItinerary(assignedDays);
      return ManualMogaResult(
        draftId: draft.id,
        inputDestinationIdsInSelectionOrder: inputIds,
        multiDay: DraftItineraryResult(
          days: itinerary.days.map((day) {
            return DraftDayPlan(
              dayNumber: day.dayNumber,
              destinationIdsInRouteOrder: _mapIndices(day.stopOrder, inputIds),
              distanceKm: day.distanceKm,
              timeHours: day.timeHours,
              legDistancesKm: day.legDistances,
              legTravelMinutes: day.legTravelMins,
              feasibility: day.feasibility,
              paretoFront: _mapPareto(day.paretoFront, inputIds),
            );
          }).toList(),
          totalDistanceKm: itinerary.totalDistanceKm,
          requestedDayCount: itinerary.requestedDayCount,
          dayCountSatisfied: itinerary.dayCountSatisfied,
          violations: itinerary.violations.map((violation) {
            return DraftDayViolation(
              dayNumber: violation.dayNumber,
              destinationId: inputIds[violation.destinationIndex],
              requiredHours: violation.requiredHours,
              availableHours: violation.availableHours,
              overByHours: violation.overByHours,
            );
          }).toList(),
        ),
      );
    } on DraftValidationException {
      rethrow;
    } catch (error) {
      throw DraftOptimizationException(error.toString());
    }
  }

  List<String> _validate(
    ItineraryDraft draft,
    ManualMogaConfiguration configuration,
  ) {
    final errors = <String>[];
    if (draft.method == PlanningMethod.circuitBased) {
      errors.add('Circuit-based drafts are not supported by this adapter.');
    }
    if (draft.method == PlanningMethod.systemGenerated &&
        draft.carsRunReference == null) {
      errors.add('System-generated draft has no CARS run reference.');
    }
    if (draft.stage != DraftStage.readyForOptimization) {
      errors.add('Draft must be ready for optimization.');
    }
    errors.addAll(draft.trip.validate());
    final selected = draft.stops.where((stop) => stop.isIncluded).toList();
    if (selected.isEmpty) errors.add('Draft has no included destinations.');
    final seenIds = <String>{};
    final seenOrders = <int>{};
    for (final stop in selected) {
      final destination = stop.destination;
      if (!isUuid(stop.destinationId)) {
        errors.add('${destination.name} does not have a valid database UUID.');
      }
      if (destination.id != stop.destinationId) {
        errors.add(
          '${destination.name} has inconsistent destination identity.',
        );
      }
      if (!seenIds.add(stop.destinationId)) {
        errors.add('Duplicate destination UUID: ${stop.destinationId}.');
      }
      if (!seenOrders.add(stop.selectionOrder)) {
        errors.add('Duplicate selection order: ${stop.selectionOrder}.');
      }
      final expectedProvenance = switch (draft.method) {
        PlanningMethod.manualSelection => StopProvenanceKind.manualSelection,
        PlanningMethod.systemGenerated => StopProvenanceKind.carsRecommendation,
        PlanningMethod.circuitBased => StopProvenanceKind.circuit,
      };
      if (stop.provenance.isEmpty ||
          !stop.provenance.any((source) => source.kind == expectedProvenance)) {
        errors.add(
          '${destination.name} has no valid ${draft.method.name} provenance.',
        );
      }
      if (stop.provenance.any((source) => source.kind != expectedProvenance)) {
        errors.add(
          '${destination.name} has provenance from another planning method.',
        );
      }
      if (destination.recordSource != DestinationRecordSource.database) {
        errors.add('${destination.name} is not verified as a database record.');
      }
      if (!destination.isActive) {
        errors.add('${destination.name} is inactive and cannot be optimized.');
      }
      if (!destination.isVerified) {
        errors.add('${destination.name} is not marked as verified.');
      }
      if (!destination.hasUsableCoordinates ||
          !destination.latitude.isFinite ||
          !destination.longitude.isFinite ||
          destination.latitude < -90 ||
          destination.latitude > 90 ||
          destination.longitude < -180 ||
          destination.longitude > 180) {
        errors.add('${destination.name} has missing or invalid coordinates.');
      }
      if (!destination.hasUsableVisitDuration ||
          destination.visitDurationMinutes < 0) {
        errors.add(
          '${destination.name} has a missing or invalid visit duration.',
        );
      }
      if (draft.trip.durationDays == 1) {
        if (stop.assignedDay != null && stop.assignedDay != 1) {
          errors.add('${destination.name} has an invalid one-day assignment.');
        }
      } else if (stop.assignedDay == null) {
        errors.add('${destination.name} is unassigned in a multi-day draft.');
      } else if (stop.assignedDay! < 1 ||
          stop.assignedDay! > draft.trip.durationDays) {
        errors.add('${destination.name} has an invalid assigned day.');
      }
    }
    if (!configuration.averageSpeedKmh.isFinite ||
        configuration.averageSpeedKmh <= 0) {
      errors.add('MO-GA travel speed must be finite and positive.');
    }
    if (configuration.populationSize <= 0 || configuration.generations < 0) {
      errors.add('MO-GA population and generation settings are invalid.');
    }
    if (!configuration.crossoverRate.isFinite ||
        configuration.crossoverRate < 0 ||
        configuration.crossoverRate > 1 ||
        !configuration.mutationRate.isFinite ||
        configuration.mutationRate < 0 ||
        configuration.mutationRate > 1) {
      errors.add('MO-GA rates must be between zero and one.');
    }
    return errors;
  }

  DraftRouteResult _mapRoute(moga.RouteResult route, List<String> inputIds) =>
      DraftRouteResult(
        destinationIdsInRouteOrder: _mapIndices(route.stopOrder, inputIds),
        totalDistanceKm: route.totalDistanceKm,
        totalTimeHours: route.totalTimeHours,
        legDistancesKm: route.legDistances,
        legTravelMinutes: route.legTravelMins,
        feasibility: route.feasibility,
        paretoFront: _mapPareto(route.paretoFront, inputIds),
        selectionPolicy: route.selectionPolicy,
      );

  List<DraftRouteParetoCandidate> _mapPareto(
    List<moga.ParetoCandidate> candidates,
    List<String> inputIds,
  ) => candidates
      .map(
        (candidate) => DraftRouteParetoCandidate(
          destinationIds: _mapIndices(candidate.stopOrder, inputIds),
          objectives: candidate.fitness,
        ),
      )
      .toList();

  List<String> _mapIndices(List<int> indices, List<String> inputIds) =>
      indices.map((index) => inputIds[index]).toList();
}
