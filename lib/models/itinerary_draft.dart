import 'dart:math';

import 'destination_record.dart';
import 'price_info.dart';

enum PlanningMethod { manualSelection, circuitBased, systemGenerated }

enum DraftStage {
  configuring,
  selecting,
  recommendationReview,
  draftReview,
  readyForOptimization,
  optimizing,
  optimizationResults,
  itineraryReview,
  saved,
}

enum BudgetBasis { totalGroup, perPerson }

enum PreferredTravelMode {
  walking,
  bicycle,
  motorcycle,
  car,
  publicTransportation,
}

extension PreferredTravelModeValue on PreferredTravelMode {
  String get value => switch (this) {
    PreferredTravelMode.walking => 'walking',
    PreferredTravelMode.bicycle => 'bicycle',
    PreferredTravelMode.motorcycle => 'motorcycle',
    PreferredTravelMode.car => 'car',
    PreferredTravelMode.publicTransportation => 'public transportation',
  };
}

/// An origin selected for this trip; live GPS is deliberately not modeled here.
class TripOrigin {
  final double latitude;
  final double longitude;
  final String? label;

  const TripOrigin({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude.isFinite &&
      longitude >= -180 &&
      longitude <= 180;
}

/// Captures a required transfer request without claiming to route or price it.
enum RequiredTransferKind { ferry, boat }

class RequiredTransfer {
  final String fromDestinationId;
  final String toDestinationId;
  final RequiredTransferKind kind;

  const RequiredTransfer({
    required this.fromDestinationId,
    required this.toDestinationId,
    required this.kind,
  });
}

class TripConfiguration {
  final DateTime? startDate;
  final int durationDays;
  final int availableHoursPerDay;
  final double? budgetMinimum;
  final double? budgetMaximum;
  final BudgetBasis? budgetBasis;
  final String? currency;
  final int? totalGroupSize;
  final int? childrenCount;
  final int? eldersCount;
  final TripOrigin? origin;
  final PreferredTravelMode? travelMode;
  final List<RequiredTransfer> requiredTransfers;

  TripConfiguration({
    this.startDate,
    required this.durationDays,
    required this.availableHoursPerDay,
    this.budgetMinimum,
    this.budgetMaximum,
    this.budgetBasis,
    this.currency,
    this.totalGroupSize,
    this.childrenCount,
    this.eldersCount,
    this.origin,
    this.travelMode,
    List<RequiredTransfer> requiredTransfers = const [],
  }) : requiredTransfers = List.unmodifiable(requiredTransfers);

  int? get adultsCount {
    final total = totalGroupSize;
    final children = childrenCount;
    final elders = eldersCount;
    if (total == null || children == null || elders == null) return null;
    if (total < 0 || children < 0 || elders < 0 || children + elders > total) {
      return null;
    }
    return total - children - elders;
  }

  List<String> validate() {
    final errors = <String>[];
    if (durationDays < 1 || durationDays > 30) {
      errors.add('Trip duration must be between 1 and 30 days.');
    }
    if (availableHoursPerDay < 1 || availableHoursPerDay > 24) {
      errors.add('Available hours must be between 1 and 24 per day.');
    }
    if (budgetMinimum != null &&
        (!budgetMinimum!.isFinite || budgetMinimum! < 0)) {
      errors.add('Budget minimum must be finite and nonnegative.');
    }
    if (budgetMaximum != null &&
        (!budgetMaximum!.isFinite || budgetMaximum! < 0)) {
      errors.add('Budget maximum must be finite and nonnegative.');
    }
    if (budgetMinimum != null &&
        budgetMaximum != null &&
        budgetMaximum! < budgetMinimum!) {
      errors.add('Budget maximum cannot be less than budget minimum.');
    }
    if (totalGroupSize != null && totalGroupSize! < 0) {
      errors.add('Total group size must be nonnegative.');
    }
    if (childrenCount != null && childrenCount! < 0) {
      errors.add('Children count must be nonnegative.');
    }
    if (eldersCount != null && eldersCount! < 0) {
      errors.add('Elders count must be nonnegative.');
    }
    if ((childrenCount != null || eldersCount != null) &&
        totalGroupSize == null) {
      errors.add(
        'Total group size is required when subgroup counts are supplied.',
      );
    }
    if (totalGroupSize != null &&
        ((childrenCount ?? 0) + (eldersCount ?? 0) > totalGroupSize!)) {
      errors.add('Children and elders cannot exceed total group size.');
    }
    if (origin != null && !origin!.hasValidCoordinates) {
      errors.add('Trip origin coordinates are invalid.');
    }
    return List.unmodifiable(errors);
  }
}

enum StopProvenanceKind { manualSelection, circuit, carsRecommendation }

/// Value object so one stop can retain multiple future source references.
class StopProvenance {
  final StopProvenanceKind kind;
  final String? sourceId;
  final String? sourceName;

  const StopProvenance({required this.kind, this.sourceId, this.sourceName});

  const StopProvenance.manual()
    : kind = StopProvenanceKind.manualSelection,
      sourceId = null,
      sourceName = null;

  @override
  bool operator ==(Object other) =>
      other is StopProvenance &&
      other.kind == kind &&
      other.sourceId == sourceId &&
      other.sourceName == sourceName;

  @override
  int get hashCode => Object.hash(kind, sourceId, sourceName);
}

class DestinationDisplaySnapshot {
  final String id;
  final String name;
  final String location;
  final String category;
  final String? categoryId;
  final double latitude;
  final double longitude;
  final int visitDurationMinutes;
  final PriceInfo entrancePrice;
  final DestinationRecordSource recordSource;
  final bool isActive;
  final bool isVerified;
  final bool hasUsableCoordinates;
  final bool hasUsableVisitDuration;

  const DestinationDisplaySnapshot({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    required this.categoryId,
    required this.latitude,
    required this.longitude,
    required this.visitDurationMinutes,
    required this.entrancePrice,
    required this.recordSource,
    required this.isActive,
    required this.isVerified,
    required this.hasUsableCoordinates,
    required this.hasUsableVisitDuration,
  });

  factory DestinationDisplaySnapshot.fromRecord(DestinationRecord record) =>
      DestinationDisplaySnapshot(
        id: record.id,
        name: record.name,
        location: record.location,
        category: record.category,
        categoryId: record.categoryId,
        latitude: record.lat,
        longitude: record.lng,
        visitDurationMinutes: record.averageStayMinutes,
        entrancePrice: record.entrancePrice,
        recordSource: record.source,
        isActive: record.isActive,
        isVerified: record.isVerified,
        hasUsableCoordinates: record.hasUsableCoordinates,
        hasUsableVisitDuration: record.hasUsableVisitDuration,
      );
}

class DraftStop {
  final String destinationId;
  final DestinationDisplaySnapshot destination;
  final int selectionOrder;
  final int? assignedDay;
  final Set<StopProvenance> provenance;
  final List<String> selectedActivityIds;
  final bool isIncluded;

  DraftStop({
    required this.destinationId,
    required this.destination,
    required this.selectionOrder,
    this.assignedDay,
    required Set<StopProvenance> provenance,
    List<String> selectedActivityIds = const [],
    this.isIncluded = true,
  }) : provenance = Set.unmodifiable(provenance),
       selectedActivityIds = List.unmodifiable(selectedActivityIds);
}

class CircuitReference {
  final String id;
  final String name;
  final String? officialSource;

  const CircuitReference({
    required this.id,
    required this.name,
    this.officialSource,
  });
}

class CarsRunReference {
  final String id;

  const CarsRunReference(this.id);
}

class DraftValidation {
  final List<String> errors;

  DraftValidation(Iterable<String> errors) : errors = List.unmodifiable(errors);

  bool get isValid => errors.isEmpty;
}

abstract interface class DraftOptimizationResult {
  const DraftOptimizationResult();
}

class ItineraryDraft {
  final String id;
  final PlanningMethod method;
  final DraftStage stage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TripConfiguration trip;
  final List<DraftStop> stops;
  final List<CircuitReference> selectedCircuits;
  final CarsRunReference? carsRunReference;
  final DraftOptimizationResult? optimizationResult;

  ItineraryDraft({
    required this.id,
    required this.method,
    required this.stage,
    required this.createdAt,
    required this.updatedAt,
    required this.trip,
    required List<DraftStop> stops,
    List<CircuitReference> selectedCircuits = const [],
    this.carsRunReference,
    this.optimizationResult,
  }) : stops = List.unmodifiable(stops),
       selectedCircuits = List.unmodifiable(selectedCircuits) {
    if (method == PlanningMethod.manualSelection &&
        this.selectedCircuits.isNotEmpty) {
      throw ArgumentError('Manual drafts cannot contain selected circuits.');
    }
    if (method == PlanningMethod.manualSelection && carsRunReference != null) {
      throw ArgumentError('Manual drafts cannot contain a CARS run reference.');
    }
  }

  factory ItineraryDraft.newManual({
    required TripConfiguration trip,
    List<DraftStop> stops = const [],
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    return ItineraryDraft(
      id: _newUuid(),
      method: PlanningMethod.manualSelection,
      stage: DraftStage.configuring,
      createdAt: timestamp,
      updatedAt: timestamp,
      trip: trip,
      stops: stops,
    );
  }

  DraftValidation validate() {
    final errors = <String>[...trip.validate()];
    final active = stops.where((stop) => stop.isIncluded).toList();
    final ids = <String>{};
    for (final stop in active) {
      if (!isUuid(stop.destinationId)) {
        errors.add(
          'Included stop ${stop.destination.name} has an invalid database UUID.',
        );
      }
      if (stop.destination.id != stop.destinationId) {
        errors.add('Stop and destination snapshot identities do not match.');
      }
      if (!ids.add(stop.destinationId)) {
        errors.add(
          'Duplicate included destination UUID: ${stop.destinationId}.',
        );
      }
      if (stop.selectionOrder < 0) {
        errors.add('Selection order must be nonnegative.');
      }
      if (stop.assignedDay != null &&
          (stop.assignedDay! < 1 || stop.assignedDay! > trip.durationDays)) {
        errors.add('Assigned day must be within the requested trip duration.');
      }
    }
    return DraftValidation(errors);
  }

  ItineraryDraft transitionTo(
    DraftStage next, {
    DraftOptimizationResult? result,
    DateTime? now,
  }) {
    if (method == PlanningMethod.circuitBased) {
      throw UnsupportedError(
        'Circuit-based draft transitions are not implemented.',
      );
    }
    final transitions = <DraftStage, Set<DraftStage>>{
      DraftStage.configuring: {DraftStage.selecting},
      DraftStage.selecting: {DraftStage.draftReview},
      DraftStage.draftReview: {
        DraftStage.selecting,
        DraftStage.readyForOptimization,
      },
      DraftStage.readyForOptimization: {DraftStage.optimizing},
      DraftStage.optimizing: {
        DraftStage.optimizationResults,
        DraftStage.draftReview,
      },
      DraftStage.optimizationResults: {
        DraftStage.itineraryReview,
        DraftStage.draftReview,
      },
      DraftStage.itineraryReview: {DraftStage.draftReview},
    };
    if (method == PlanningMethod.systemGenerated) {
      transitions[DraftStage.recommendationReview] = {
        DraftStage.draftReview,
        DraftStage.readyForOptimization,
      };
      transitions[DraftStage.optimizing] = {
        DraftStage.optimizationResults,
        DraftStage.recommendationReview,
      };
      transitions[DraftStage.optimizationResults] = {
        DraftStage.itineraryReview,
        DraftStage.recommendationReview,
      };
      transitions[DraftStage.itineraryReview] = {
        DraftStage.recommendationReview,
      };
    }
    if (!(transitions[stage]?.contains(next) ?? false)) {
      throw StateError('Invalid draft transition: $stage -> $next.');
    }
    if (next == DraftStage.optimizationResults && result == null) {
      throw ArgumentError('An optimization result is required for that stage.');
    }
    return ItineraryDraft(
      id: id,
      method: method,
      stage: next,
      createdAt: createdAt,
      updatedAt: (now ?? DateTime.now()).toUtc(),
      trip: trip,
      stops: stops,
      selectedCircuits: selectedCircuits,
      carsRunReference: carsRunReference,
      optimizationResult: switch (next) {
        DraftStage.optimizationResults => result,
        DraftStage.itineraryReview => optimizationResult,
        _ => null,
      },
    );
  }
}

bool isUuid(String value) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
).hasMatch(value);

String _newUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
