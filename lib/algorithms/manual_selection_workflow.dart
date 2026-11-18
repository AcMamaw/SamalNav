import '../models/destination_record.dart';
import '../models/itinerary_draft.dart';
import 'manual_selection_moga_adapter.dart';
import 'moga_engine.dart' as moga;
import 'package:latlong2/latlong.dart';

/// Moves a selected destination within one day's insertion-ordered selection.
/// Returns false when the destination is missing or already at that boundary.
/// The caller supplies only one day's selection, so day assignment is stable.
bool moveDestinationWithinDay(
  Set<String> daySelection, {
  required String destinationId,
  required int offset,
}) {
  if (offset != -1 && offset != 1) {
    throw ArgumentError.value(offset, 'offset', 'Must be -1 or 1.');
  }
  final order = daySelection.toList();
  final currentIndex = order.indexOf(destinationId);
  final nextIndex = currentIndex + offset;
  if (currentIndex == -1 || nextIndex < 0 || nextIndex >= order.length) {
    return false;
  }
  final destination = order.removeAt(currentIndex);
  order.insert(nextIndex, destination);
  daySelection
    ..clear()
    ..addAll(order);
  return true;
}

/// Builds the shared manual-selection draft from the planner's selected day
/// groups. Day group order and each group's insertion order are retained.
class ManualSelectionDraftBuilder {
  const ManualSelectionDraftBuilder();

  ItineraryDraft build({
    required List<DestinationRecord> destinations,
    required List<List<String>> daySelections,
    required TripConfiguration trip,
    ItineraryDraft? existingDraft,
    DateTime? now,
  }) {
    if (daySelections.length != trip.durationDays) {
      throw ArgumentError(
        'There must be one destination group for each trip day.',
      );
    }
    if (existingDraft != null &&
        existingDraft.method != PlanningMethod.manualSelection) {
      throw ArgumentError('Only a manual-selection draft can be updated.');
    }

    final stops = <DraftStop>[];
    final existingStops = <String, DraftStop>{
      if (existingDraft != null)
        for (final stop in existingDraft.stops) stop.destinationId: stop,
    };
    final destinationById = <String, DestinationRecord>{
      for (final destination in destinations) destination.id: destination,
    };
    if (destinationById.length != destinations.length) {
      throw ArgumentError(
        'The destination directory contains duplicate UUIDs.',
      );
    }
    final seenIds = <String>{};
    for (var dayIndex = 0; dayIndex < daySelections.length; dayIndex++) {
      for (final destinationId in daySelections[dayIndex]) {
        final record = destinationById[destinationId];
        if (record == null) {
          throw ArgumentError(
            'Selected destination $destinationId is not in the directory.',
          );
        }
        if (!seenIds.add(destinationId)) {
          throw ArgumentError(
            'A destination cannot be assigned to multiple days.',
          );
        }
        stops.add(
          DraftStop(
            destinationId: record.id,
            destination: DestinationDisplaySnapshot.fromRecord(record),
            selectionOrder: stops.length,
            assignedDay: trip.durationDays == 1 ? null : dayIndex + 1,
            provenance:
                existingStops[record.id]?.provenance ??
                {StopProvenance.manual()},
            selectedActivityIds:
                existingStops[record.id]?.selectedActivityIds ?? const [],
            isIncluded: existingStops[record.id]?.isIncluded ?? true,
          ),
        );
      }
    }

    final timestamp = (now ?? DateTime.now()).toUtc();
    if (existingDraft == null) {
      final draft = ItineraryDraft.newManual(
        trip: trip,
        stops: stops,
        now: timestamp,
      );
      return draft
          .transitionTo(DraftStage.selecting, now: timestamp)
          .transitionTo(DraftStage.draftReview, now: timestamp);
    }

    return ItineraryDraft(
      id: existingDraft.id,
      method: PlanningMethod.manualSelection,
      stage: DraftStage.draftReview,
      createdAt: existingDraft.createdAt,
      updatedAt: timestamp,
      trip: trip,
      stops: stops,
    );
  }
}

class ManualSelectionMappedResult {
  final moga.RouteResult? dayResult;
  final moga.ItineraryResult? itineraryResult;
  final List<List<LatLng>> routeSegments;

  ManualSelectionMappedResult({
    required this.dayResult,
    required this.itineraryResult,
    required List<List<LatLng>> routeSegments,
  }) : routeSegments = List.unmodifiable(
         routeSegments.map((segment) => List<LatLng>.unmodifiable(segment)),
       );
}

/// Maps UUID-based adapter output into the legacy results screen's display
/// indexes. The source draft and adapter result remain UUID-based.
class ManualSelectionResultMapper {
  const ManualSelectionResultMapper();

  ManualSelectionMappedResult map(
    ManualMogaResult result,
    List<DestinationRecord> destinations,
  ) {
    final indexById = <String, int>{
      for (var index = 0; index < destinations.length; index++)
        destinations[index].id: index,
    };
    int indexFor(String id) {
      final index = indexById[id];
      if (index == null) {
        throw StateError(
          'Optimized destination $id is absent from the directory.',
        );
      }
      return index;
    }

    moga.ParetoCandidate mapCandidate(DraftRouteParetoCandidate candidate) =>
        moga.ParetoCandidate(
          stopOrder: candidate.destinationIds.map(indexFor).toList(),
          fitness: candidate.objectives,
        );

    final route = result.oneDay;
    if (route != null) {
      final order = route.destinationIdsInRouteOrder.map(indexFor).toList();
      return ManualSelectionMappedResult(
        dayResult: moga.RouteResult(
          stopOrder: order,
          totalDistanceKm: route.totalDistanceKm,
          totalTimeHours: route.totalTimeHours,
          legDistances: route.legDistancesKm,
          legTravelMins: route.legTravelMinutes,
          feasibility: route.feasibility,
          paretoFront: route.paretoFront.map(mapCandidate).toList(),
          selectionPolicy: route.selectionPolicy,
        ),
        itineraryResult: null,
        routeSegments: [
          order
              .map(
                (index) =>
                    LatLng(destinations[index].lat, destinations[index].lng),
              )
              .toList(),
        ],
      );
    }

    final itinerary = result.multiDay!;
    final days = itinerary.days.map((day) {
      final order = day.destinationIdsInRouteOrder.map(indexFor).toList();
      return moga.DayPlan(
        dayNumber: day.dayNumber,
        stopOrder: order,
        distanceKm: day.distanceKm,
        timeHours: day.timeHours,
        legDistances: day.legDistancesKm,
        legTravelMins: day.legTravelMinutes,
        feasibility: day.feasibility,
        paretoFront: day.paretoFront.map(mapCandidate).toList(),
      );
    }).toList();
    return ManualSelectionMappedResult(
      dayResult: null,
      itineraryResult: moga.ItineraryResult(
        days: days,
        totalDistanceKm: itinerary.totalDistanceKm,
        requestedDayCount: itinerary.requestedDayCount,
        dayCountSatisfied: itinerary.dayCountSatisfied,
        violations: itinerary.violations
            .map(
              (violation) => moga.DayViolation(
                dayNumber: violation.dayNumber,
                destinationIndex: indexFor(violation.destinationId),
                requiredHours: violation.requiredHours,
                availableHours: violation.availableHours,
                overByHours: violation.overByHours,
              ),
            )
            .toList(),
      ),
      routeSegments: days
          .map(
            (day) => day.stopOrder
                .map(
                  (index) =>
                      LatLng(destinations[index].lat, destinations[index].lng),
                )
                .toList(),
          )
          .toList(),
    );
  }
}
