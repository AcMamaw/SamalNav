import 'dart:async';

import 'package:flutter/material.dart';

import '../../algorithms/manual_selection_moga_adapter.dart';
import '../../models/itinerary_draft.dart';

typedef SystemDraftOptimizer =
    FutureOr<ManualMogaResult> Function(ItineraryDraft readyDraft);

/// Reviews a tourist-selected CARS draft and runs MO-GA only on explicit ask.
class SystemGeneratedDraftReviewPage extends StatefulWidget {
  final ItineraryDraft draft;
  final SystemDraftOptimizer? optimizer;

  const SystemGeneratedDraftReviewPage({
    super.key,
    required this.draft,
    this.optimizer,
  });

  @override
  State<SystemGeneratedDraftReviewPage> createState() =>
      _SystemGeneratedDraftReviewPageState();
}

class _SystemGeneratedDraftReviewPageState
    extends State<SystemGeneratedDraftReviewPage> {
  late ItineraryDraft _draft = widget.draft;
  bool _isOptimizing = false;
  String? _error;

  Future<void> _optimize() async {
    setState(() {
      _isOptimizing = true;
      _error = null;
    });
    try {
      final ready = _draft.transitionTo(DraftStage.readyForOptimization);
      final optimizing = ready.transitionTo(DraftStage.optimizing);
      final result = await (widget.optimizer ?? _runExistingMoga)(ready);
      final expected = ready.stops
          .where((stop) => stop.isIncluded)
          .map((stop) => stop.destinationId)
          .toSet();
      final returned = _resultIds(result);
      if (returned.length != expected.length ||
          returned.toSet().length != expected.length ||
          returned.toSet().difference(expected).isNotEmpty ||
          expected.difference(returned.toSet()).isNotEmpty) {
        throw const DraftOptimizationException(
          'MO-GA returned an incomplete or inconsistent route. Your selected destinations remain in the draft.',
        );
      }
      final withResults = optimizing.transitionTo(
        DraftStage.optimizationResults,
        result: result,
      );
      final reordered = _orderedForResult(withResults, result);
      if (!mounted) return;
      setState(() => _draft = reordered);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst(
          'Draft optimization failed: ',
          '',
        );
      });
    } finally {
      if (mounted) setState(() => _isOptimizing = false);
    }
  }

  FutureOr<ManualMogaResult> _runExistingMoga(ItineraryDraft readyDraft) {
    return const ManualSelectionMogaAdapter().optimize(readyDraft);
  }

  void _accept() {
    try {
      final accepted = _draft.transitionTo(DraftStage.itineraryReview);
      Navigator.of(context).pop(accepted);
    } on Object catch (error) {
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _draft.optimizationResult;
    return Scaffold(
      appBar: AppBar(title: const Text('Review system-generated itinerary')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTripSummary(),
            const SizedBox(height: 12),
            const Text(
              'Selected destinations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            for (final stop in ([
              ..._draft.stops,
            ]..sort((a, b) => a.selectionOrder.compareTo(b.selectionOrder))))
              ListTile(
                key: Key('system_draft_stop_${stop.destinationId}'),
                leading: Icon(
                  stop.isIncluded
                      ? Icons.place_outlined
                      : Icons.remove_circle_outline,
                ),
                title: Text(stop.destination.name),
                subtitle: Text(
                  '${stop.isIncluded ? 'Selected' : 'Not included'}'
                  '${_draft.trip.durationDays > 1 ? ' · Assigned day ${stop.assignedDay}' : ''}',
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  key: const Key('system_draft_optimization_error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (result == null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'This is an unoptimized draft. MO-GA will run only when you choose the action below. CARS scores are not recalculated during route optimization. A valid supplied origin is used for the first assigned day; without one, that inbound leg is omitted.',
                ),
              ),
              FilledButton.icon(
                key: const Key('optimize_system_draft'),
                onPressed: _isOptimizing ? null : _optimize,
                icon: _isOptimizing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.route),
                label: Text(
                  _isOptimizing ? 'Optimizing…' : 'Optimize with MO-GA',
                ),
              ),
            ] else ...[
              _buildOptimizationResult(result),
              const SizedBox(height: 16),
              const Text(
                'Review the proposed route. Accepting returns this itinerary to the caller as an in-memory review result; it is not saved or marked completed.',
              ),
              FilledButton.icon(
                key: const Key('accept_system_optimized_itinerary'),
                onPressed: _accept,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Accept itinerary for review'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _draft = _draft.transitionTo(DraftStage.recommendationReview);
                  _error = null;
                }),
                child: const Text('Discard optimization and return to draft'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummary() {
    final trip = _draft.trip;
    final origin = trip.origin;
    return Card(
      child: ListTile(
        key: const Key('system_draft_trip_summary'),
        leading: const Icon(Icons.tune),
        title: Text(
          '${trip.durationDays} day(s), ${trip.availableHoursPerDay} hours per day',
        ),
        subtitle: Text(
          origin == null
              ? 'No starting point supplied; the first travel leg cannot be estimated.'
              : !origin.hasValidCoordinates
              ? 'The supplied starting point has invalid coordinates; optimization cannot run.'
              : 'Tourist-selected starting point: ${origin.label ?? '${origin.latitude}, ${origin.longitude}'}',
        ),
      ),
    );
  }

  Widget _buildOptimizationResult(DraftOptimizationResult result) {
    if (result is! ManualMogaResult) {
      return const Text('The optimizer returned an unsupported result type.');
    }
    if (result.oneDay case final day?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _originEstimateNote(),
          _buildDay(
            dayNumber: 1,
            ids: day.destinationIdsInRouteOrder,
            feasible: day.feasibility.isFeasible,
            requiredHours: day.feasibility.requiredHours,
            availableHours: day.feasibility.availableHours,
            distanceKm: day.totalDistanceKm,
          ),
        ],
      );
    }
    final itinerary = result.multiDay;
    if (itinerary == null) {
      return const Text('MO-GA returned no itinerary result.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _originEstimateNote(),
        for (final day in itinerary.days)
          _buildDay(
            dayNumber: day.dayNumber,
            ids: day.destinationIdsInRouteOrder,
            feasible: day.feasibility.isFeasible,
            requiredHours: day.timeHours,
            availableHours: _draft.trip.availableHoursPerDay.toDouble(),
            distanceKm: day.distanceKm,
          ),
        if (itinerary.violations.isNotEmpty)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Some assigned days exceed the available time. All selected destinations remain listed; review these conflicts before accepting.',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDay({
    required int dayNumber,
    required List<String> ids,
    required bool feasible,
    required double requiredHours,
    required double availableHours,
    required double distanceKm,
  }) {
    final names = {
      for (final stop in _draft.stops)
        stop.destinationId: stop.destination.name,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day $dayNumber route',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            for (var index = 0; index < ids.length; index++)
              Text('${index + 1}. ${names[ids[index]] ?? ids[index]}'),
            Text('Distance estimate: ${distanceKm.toStringAsFixed(2)} km'),
            Text(
              'Visit and travel time: ${requiredHours.toStringAsFixed(2)} / ${availableHours.toStringAsFixed(2)} hours',
            ),
            Text(
              feasible ? 'Within daily time limit' : 'Exceeds daily time limit',
            ),
            if (!feasible)
              const Text(
                'The selected destinations were retained; MO-GA reports this day as infeasible.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _originEstimateNote() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'MO-GA uses the existing Haversine times 1.3 distance approximation at 30 km/h. A valid supplied origin is used for the first non-empty assigned day only. Later days have no verified overnight start location in this draft, so no base location is assumed. If origin coordinates are missing, the inbound leg is omitted. No road routing or traffic data is used.',
    ),
  );
}

List<String> _resultIds(ManualMogaResult result) {
  if (result.oneDay case final day?) return day.destinationIdsInRouteOrder;
  return result.multiDay?.days
          .expand((day) => day.destinationIdsInRouteOrder)
          .toList() ??
      const [];
}

ItineraryDraft _orderedForResult(
  ItineraryDraft draft,
  ManualMogaResult result,
) {
  final order = _resultIds(result);
  final included = {
    for (final stop in draft.stops.where((stop) => stop.isIncluded))
      stop.destinationId: stop,
  };
  final reordered = <DraftStop>[
    for (var index = 0; index < order.length; index++)
      _copyStop(included[order[index]]!, selectionOrder: index),
    ...draft.stops.where((stop) => !stop.isIncluded),
  ];
  return ItineraryDraft(
    id: draft.id,
    method: draft.method,
    stage: draft.stage,
    createdAt: draft.createdAt,
    updatedAt: draft.updatedAt,
    trip: draft.trip,
    stops: reordered,
    selectedCircuits: draft.selectedCircuits,
    carsRunReference: draft.carsRunReference,
    optimizationResult: draft.optimizationResult,
  );
}

DraftStop _copyStop(DraftStop stop, {required int selectionOrder}) => DraftStop(
  destinationId: stop.destinationId,
  destination: stop.destination,
  selectionOrder: selectionOrder,
  assignedDay: stop.assignedDay,
  provenance: stop.provenance,
  selectedActivityIds: stop.selectedActivityIds,
  isIncluded: stop.isIncluded,
);
