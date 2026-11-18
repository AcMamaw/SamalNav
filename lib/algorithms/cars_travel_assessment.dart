import 'dart:math';

import '../models/itinerary_draft.dart';

/// Validated geographic point. This is geometry only; it says nothing about
/// roads, access, transfers, or travel time.
class TravelCoordinate {
  final double latitude;
  final double longitude;

  const TravelCoordinate(this.latitude, this.longitude);

  bool get isValid =>
      latitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude.isFinite &&
      longitude >= -180 &&
      longitude <= 180;
}

/// Great-circle distance between valid coordinates, in kilometers.
/// This must not be described as road or estimated travel distance.
double? straightLineDistanceKm(TravelCoordinate from, TravelCoordinate to) {
  if (!from.isValid || !to.isValid) return null;
  const earthRadiusKm = 6371.0;
  double radians(double value) => value * pi / 180;
  final latitudeDelta = radians(to.latitude - from.latitude);
  final longitudeDelta = radians(to.longitude - from.longitude);
  final a =
      sin(latitudeDelta / 2) * sin(latitudeDelta / 2) +
      cos(radians(from.latitude)) *
          cos(radians(to.latitude)) *
          sin(longitudeDelta / 2) *
          sin(longitudeDelta / 2);
  final boundedA = a.clamp(0.0, 1.0);
  return earthRadiusKm * 2 * atan2(sqrt(boundedA), sqrt(1 - boundedA));
}

class TravelRouteRequest {
  final TravelCoordinate from;
  final TravelCoordinate to;
  final PreferredTravelMode mode;
  final DateTime itineraryDate;

  const TravelRouteRequest({
    required this.from,
    required this.to,
    required this.mode,
    required this.itineraryDate,
  });
}

/// Route data returned by an explicitly selected provider. Provenance and
/// freshness are required before an estimate is accepted for assessment.
class TravelRouteEstimate {
  final PreferredTravelMode mode;
  final double routeDistanceKm;
  final double durationMinutes;
  final String source;
  final DateTime retrievedAt;
  final DateTime? freshUntil;

  const TravelRouteEstimate({
    required this.mode,
    required this.routeDistanceKm,
    required this.durationMinutes,
    required this.source,
    required this.retrievedAt,
    required this.freshUntil,
  });
}

/// Provider boundary only. No provider, speed table, or route fabrication is
/// supplied by this module.
abstract interface class TravelRoutingProvider {
  bool supports(PreferredTravelMode mode);

  Future<TravelRouteEstimate?> estimateRoute(TravelRouteRequest request);
}

enum TravelLegKind {
  originToFirstStop,
  betweenStops,
  unknownOvernightStart,
  requiredFerryOrBoatTransfer,
}

enum TravelEstimateState { available, unavailable, stale }

class TravelLegAssessment {
  final String? fromDestinationId;
  final String toDestinationId;
  final TravelLegKind kind;
  final double? straightLineKm;
  final double? routeDistanceKm;
  final double? estimatedTravelMinutes;
  final TravelEstimateState state;
  final String explanation;
  final String? source;
  final DateTime? retrievedAt;

  const TravelLegAssessment({
    required this.fromDestinationId,
    required this.toDestinationId,
    required this.kind,
    required this.straightLineKm,
    required this.routeDistanceKm,
    required this.estimatedTravelMinutes,
    required this.state,
    required this.explanation,
    required this.source,
    required this.retrievedAt,
  });
}

enum AvailableTimeCompatibility {
  withinAvailableTime,
  exceedsAvailableTime,
  unknown,
}

class TravelDayAssessment {
  final int dayNumber;
  final DateTime? itineraryDate;
  final double? availableMinutes;
  final double? totalStraightLineKm;
  final double? totalRouteDistanceKm;
  final double? totalEstimatedTravelMinutes;
  final AvailableTimeCompatibility timeCompatibility;
  final List<TravelLegAssessment> legs;
  final List<String> limitations;

  TravelDayAssessment({
    required this.dayNumber,
    required this.itineraryDate,
    required this.availableMinutes,
    required this.totalStraightLineKm,
    required this.totalRouteDistanceKm,
    required this.totalEstimatedTravelMinutes,
    required this.timeCompatibility,
    required List<TravelLegAssessment> legs,
    required List<String> limitations,
  }) : legs = List.unmodifiable(legs),
       limitations = List.unmodifiable(limitations);

  bool get hasCompleteRouteData =>
      availableMinutes != null &&
      legs.every((leg) => leg.state == TravelEstimateState.available);
}

class CarsTravelAssessment {
  final List<TravelDayAssessment> days;
  final List<String> limitations;

  CarsTravelAssessment({
    required List<TravelDayAssessment> days,
    required List<String> limitations,
  }) : days = List.unmodifiable(days),
       limitations = List.unmodifiable(limitations);

  bool get hasCompleteRouteData =>
      limitations.isEmpty && days.every((day) => day.hasCompleteRouteData);
}

/// Assesses known straight-line geometry and optional provider-backed route
/// estimates without changing CARS scores or MO-GA optimization behavior.
class CarsTravelAssessmentService {
  const CarsTravelAssessmentService();

  Future<CarsTravelAssessment> assess(
    ItineraryDraft draft, {
    TravelRoutingProvider? provider,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final included = draft.stops.where((stop) => stop.isIncluded).toList()
      ..sort((a, b) => a.selectionOrder.compareTo(b.selectionOrder));
    final overallLimitations = <String>[];
    final unassigned = included.where((stop) => stop.assignedDay == null);
    if (draft.trip.durationDays > 1 && unassigned.isNotEmpty) {
      overallLimitations.add(
        '${unassigned.length} selected stop(s) have no assigned trip day and were not routed.',
      );
    }
    final outOfRange = included.where(
      (stop) =>
          stop.assignedDay != null &&
          (stop.assignedDay! < 1 ||
              stop.assignedDay! > draft.trip.durationDays),
    );
    if (outOfRange.isNotEmpty) {
      overallLimitations.add(
        '${outOfRange.length} selected stop(s) have an out-of-range day assignment and were not routed.',
      );
    }
    if (draft.trip.durationDays < 1 || draft.trip.durationDays > 30) {
      overallLimitations.add(
        'Trip duration is outside the supported 1-30 day range.',
      );
    }

    final days = <TravelDayAssessment>[];
    for (var dayNumber = 1; dayNumber <= draft.trip.durationDays; dayNumber++) {
      final dayStops = included.where((stop) {
        if (draft.trip.durationDays == 1) {
          return stop.assignedDay == null || stop.assignedDay == dayNumber;
        }
        return stop.assignedDay == dayNumber;
      }).toList();
      final itineraryDate = draft.trip.startDate?.add(
        Duration(days: dayNumber - 1),
      );
      final limits = <String>[];
      final availableMinutes =
          draft.trip.availableHoursPerDay >= 1 &&
              draft.trip.availableHoursPerDay <= 24
          ? draft.trip.availableHoursPerDay * 60.0
          : null;
      if (availableMinutes == null) {
        limits.add('Available travel time is invalid or unavailable.');
      }
      if (itineraryDate == null) {
        limits.add(
          'Trip date is unavailable; date-dependent routing was skipped.',
        );
      }
      final legs = <TravelLegAssessment>[];
      if (dayStops.isNotEmpty) {
        if (dayNumber == 1) {
          final origin = draft.trip.origin;
          if (origin == null || !origin.hasValidCoordinates) {
            legs.add(
              _unavailableLeg(
                fromId: null,
                toId: dayStops.first.destinationId,
                kind: TravelLegKind.originToFirstStop,
                straightLineKm: null,
                reason: origin == null
                    ? 'Tourist-selected trip origin is unavailable.'
                    : 'Tourist-selected trip origin coordinates are invalid.',
              ),
            );
          } else {
            legs.add(
              await _assessLeg(
                from: TravelCoordinate(origin.latitude, origin.longitude),
                fromId: null,
                to: _coordinate(dayStops.first),
                toId: dayStops.first.destinationId,
                kind: TravelLegKind.originToFirstStop,
                date: itineraryDate,
                mode: draft.trip.travelMode,
                transfers: draft.trip.requiredTransfers,
                provider: provider,
                now: currentTime,
              ),
            );
          }
        } else {
          legs.add(
            _unavailableLeg(
              fromId: null,
              toId: dayStops.first.destinationId,
              kind: TravelLegKind.unknownOvernightStart,
              straightLineKm: null,
              reason:
                  'Overnight starting location is not represented in the trip data.',
            ),
          );
        }
        for (var index = 1; index < dayStops.length; index++) {
          final fromStop = dayStops[index - 1];
          final toStop = dayStops[index];
          legs.add(
            await _assessLeg(
              from: _coordinate(fromStop),
              fromId: fromStop.destinationId,
              to: _coordinate(toStop),
              toId: toStop.destinationId,
              kind:
                  _hasRequiredTransfer(
                    draft.trip.requiredTransfers,
                    fromStop.destinationId,
                    toStop.destinationId,
                  )
                  ? TravelLegKind.requiredFerryOrBoatTransfer
                  : TravelLegKind.betweenStops,
              date: itineraryDate,
              mode: draft.trip.travelMode,
              transfers: draft.trip.requiredTransfers,
              provider: provider,
              now: currentTime,
            ),
          );
        }
      }

      for (final leg in legs) {
        if (leg.state != TravelEstimateState.available) {
          limits.add(leg.explanation);
        }
      }
      final allGeometryKnown = legs.every((leg) => leg.straightLineKm != null);
      final allRoutesKnown = legs.every(
        (leg) => leg.state == TravelEstimateState.available,
      );
      final straightLineTotal = allGeometryKnown
          ? legs.fold<double>(0, (sum, leg) => sum + leg.straightLineKm!)
          : null;
      final routeTotal = allRoutesKnown
          ? legs.fold<double>(0, (sum, leg) => sum + leg.routeDistanceKm!)
          : null;
      final timeTotal = allRoutesKnown
          ? legs.fold<double>(
              0,
              (sum, leg) => sum + leg.estimatedTravelMinutes!,
            )
          : null;
      final compatibility = availableMinutes == null || timeTotal == null
          ? AvailableTimeCompatibility.unknown
          : timeTotal <= availableMinutes
          ? AvailableTimeCompatibility.withinAvailableTime
          : AvailableTimeCompatibility.exceedsAvailableTime;
      if (timeTotal != null) {
        limits.add(
          'Travel-time comparison includes routing time only; visit, waiting, meal, and transfer durations are not included.',
        );
      }
      days.add(
        TravelDayAssessment(
          dayNumber: dayNumber,
          itineraryDate: itineraryDate,
          availableMinutes: availableMinutes,
          totalStraightLineKm: straightLineTotal,
          totalRouteDistanceKm: routeTotal,
          totalEstimatedTravelMinutes: timeTotal,
          timeCompatibility: compatibility,
          legs: legs,
          limitations: limits.toSet().toList(),
        ),
      );
    }
    return CarsTravelAssessment(days: days, limitations: overallLimitations);
  }

  TravelCoordinate _coordinate(DraftStop stop) =>
      stop.destination.hasUsableCoordinates
      ? TravelCoordinate(stop.destination.latitude, stop.destination.longitude)
      : const TravelCoordinate(double.nan, double.nan);

  bool _hasRequiredTransfer(
    List<RequiredTransfer> transfers,
    String from,
    String to,
  ) => transfers.any(
    (transfer) =>
        transfer.fromDestinationId == from && transfer.toDestinationId == to,
  );

  TravelLegAssessment _unavailableLeg({
    required String? fromId,
    required String toId,
    required TravelLegKind kind,
    required double? straightLineKm,
    required String reason,
  }) => TravelLegAssessment(
    fromDestinationId: fromId,
    toDestinationId: toId,
    kind: kind,
    straightLineKm: straightLineKm,
    routeDistanceKm: null,
    estimatedTravelMinutes: null,
    state: TravelEstimateState.unavailable,
    explanation: reason,
    source: null,
    retrievedAt: null,
  );

  Future<TravelLegAssessment> _assessLeg({
    required TravelCoordinate from,
    required String? fromId,
    required TravelCoordinate to,
    required String toId,
    required TravelLegKind kind,
    required DateTime? date,
    required PreferredTravelMode? mode,
    required List<RequiredTransfer> transfers,
    required TravelRoutingProvider? provider,
    required DateTime now,
  }) async {
    final geometry = straightLineDistanceKm(from, to);
    if (kind == TravelLegKind.requiredFerryOrBoatTransfer) {
      return _unavailableLeg(
        fromId: fromId,
        toId: toId,
        kind: kind,
        straightLineKm: geometry,
        reason:
            'A required ferry/boat transfer is recorded, but its schedule and duration are unavailable; no land route was substituted.',
      );
    }
    if (!from.isValid || !to.isValid) {
      return _unavailableLeg(
        fromId: fromId,
        toId: toId,
        kind: kind,
        straightLineKm: null,
        reason: 'A route endpoint has missing or invalid coordinates.',
      );
    }
    if (date == null) {
      return _unavailableLeg(
        fromId: fromId,
        toId: toId,
        kind: kind,
        straightLineKm: geometry,
        reason: 'Trip date is missing, so route estimation was not requested.',
      );
    }
    if (mode == null) {
      return _unavailableLeg(
        fromId: fromId,
        toId: toId,
        kind: kind,
        straightLineKm: geometry,
        reason:
            'Travel mode is not selected; no mode-specific route estimate is available.',
      );
    }
    if (provider == null || !provider.supports(mode)) {
      return _unavailableLeg(
        fromId: fromId,
        toId: toId,
        kind: kind,
        straightLineKm: geometry,
        reason: 'No configured routing provider supports ${mode.value}.',
      );
    }
    if (transfers.any(
      (transfer) =>
          transfer.fromDestinationId == fromId &&
          transfer.toDestinationId == toId,
    )) {
      return _unavailableLeg(
        fromId: fromId,
        toId: toId,
        kind: kind,
        straightLineKm: geometry,
        reason:
            'A required transfer is recorded for this leg; land routing was not used.',
      );
    }
    try {
      final estimate = await provider.estimateRoute(
        TravelRouteRequest(from: from, to: to, mode: mode, itineraryDate: date),
      );
      if (estimate == null ||
          estimate.mode != mode ||
          !estimate.routeDistanceKm.isFinite ||
          estimate.routeDistanceKm < 0 ||
          !estimate.durationMinutes.isFinite ||
          estimate.durationMinutes < 0 ||
          estimate.source.trim().isEmpty ||
          estimate.freshUntil == null ||
          estimate.retrievedAt.isAfter(now)) {
        return _unavailableLeg(
          fromId: fromId,
          toId: toId,
          kind: kind,
          straightLineKm: geometry,
          reason:
              'Routing provider returned incomplete or invalid route metadata.',
        );
      }
      if (estimate.freshUntil!.isBefore(now)) {
        return TravelLegAssessment(
          fromDestinationId: fromId,
          toDestinationId: toId,
          kind: kind,
          straightLineKm: geometry,
          routeDistanceKm: null,
          estimatedTravelMinutes: null,
          state: TravelEstimateState.stale,
          explanation: 'Routing provider estimate is stale.',
          source: estimate.source,
          retrievedAt: estimate.retrievedAt,
        );
      }
      return TravelLegAssessment(
        fromDestinationId: fromId,
        toDestinationId: toId,
        kind: kind,
        straightLineKm: geometry,
        routeDistanceKm: estimate.routeDistanceKm,
        estimatedTravelMinutes: estimate.durationMinutes,
        state: TravelEstimateState.available,
        explanation: 'Route estimate supplied for ${mode.value}.',
        source: estimate.source,
        retrievedAt: estimate.retrievedAt,
      );
    } catch (_) {
      return _unavailableLeg(
        fromId: fromId,
        toId: toId,
        kind: kind,
        straightLineKm: geometry,
        reason:
            'Routing provider failed; route distance and travel time are unavailable.',
      );
    }
  }
}
