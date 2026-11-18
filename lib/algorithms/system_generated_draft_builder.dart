import 'dart:math';

import '../models/cars_models.dart';
import '../models/destination_record.dart';
import '../models/itinerary_draft.dart';

/// Converts a tourist-reviewed CARS selection into the shared draft contract.
/// This builder does not score candidates or run MO-GA.
class SystemGeneratedDraftBuilder {
  const SystemGeneratedDraftBuilder();

  ItineraryDraft build({
    required CarsRankingResult ranking,
    required List<String> selectedDestinationIds,
    required Map<String, int> assignedDays,
    required List<DestinationRecord> destinations,
    required TripConfiguration trip,
    required CarsRunReference carsRunReference,
    DateTime? now,
  }) {
    final tripErrors = trip.validate();
    if (tripErrors.isNotEmpty) {
      throw ArgumentError('Invalid trip context: ${tripErrors.join(' ')}');
    }
    if (carsRunReference.id.trim().isEmpty) {
      throw ArgumentError.value(
        carsRunReference.id,
        'carsRunReference.id',
        'Must not be empty.',
      );
    }
    if (selectedDestinationIds.isEmpty) {
      throw ArgumentError('Select at least one CARS recommendation.');
    }
    if (selectedDestinationIds.toSet().length !=
        selectedDestinationIds.length) {
      throw ArgumentError(
        'A recommended destination can only be selected once.',
      );
    }

    final rankedById = {
      for (final result in ranking.ranked) result.destinationId: result,
    };
    final destinationsById = {
      for (final destination in destinations) destination.id: destination,
    };
    final stops = <DraftStop>[];
    for (var index = 0; index < selectedDestinationIds.length; index++) {
      final id = selectedDestinationIds[index];
      final result = rankedById[id];
      final destination = destinationsById[id];
      if (result == null || destination == null) {
        throw ArgumentError(
          'Selected destination $id is not present in the ranked results and directory.',
        );
      }
      if (destination.source != DestinationRecordSource.database ||
          !destination.isActive ||
          !destination.isVerified) {
        throw ArgumentError(
          '${destination.name} is not a verified active database destination.',
        );
      }

      final assignedDay = trip.durationDays == 1 ? null : assignedDays[id];
      if (trip.durationDays > 1 &&
          (assignedDay == null ||
              assignedDay < 1 ||
              assignedDay > trip.durationDays)) {
        throw ArgumentError(
          'Assign ${destination.name} to a day from 1 to ${trip.durationDays}.',
        );
      }
      stops.add(
        DraftStop(
          destinationId: destination.id,
          destination: DestinationDisplaySnapshot.fromRecord(destination),
          selectionOrder: index,
          assignedDay: assignedDay,
          provenance: {
            StopProvenance(
              kind: StopProvenanceKind.carsRecommendation,
              sourceId: carsRunReference.id,
              sourceName: 'Context-Aware Recommendation System (CARS)',
            ),
          },
        ),
      );
    }

    final timestamp = (now ?? DateTime.now()).toUtc();
    return ItineraryDraft(
      id: _newDraftId(),
      method: PlanningMethod.systemGenerated,
      stage: DraftStage.recommendationReview,
      createdAt: timestamp,
      updatedAt: timestamp,
      trip: trip,
      stops: stops,
      carsRunReference: carsRunReference,
    );
  }

  String _newDraftId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
