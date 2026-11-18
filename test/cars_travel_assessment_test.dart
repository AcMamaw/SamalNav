import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/cars_travel_assessment.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';
import 'package:samal_nav/models/price_info.dart';

final assessmentNow = DateTime.utc(2026, 11, 18, 4);

DraftStop stop(
  String id,
  int order, {
  int? day = 1,
  double latitude = 10,
  double longitude = 10,
}) => DraftStop(
  destinationId: id,
  destination: DestinationDisplaySnapshot(
    id: id,
    name: id,
    location: 'Test location',
    category: 'Test',
    categoryId: null,
    latitude: latitude,
    longitude: longitude,
    visitDurationMinutes: 30,
    entrancePrice: PriceInfo.fromRaw(null),
    recordSource: DestinationRecordSource.database,
    isActive: true,
    isVerified: true,
    hasUsableCoordinates: true,
    hasUsableVisitDuration: true,
  ),
  selectionOrder: order,
  assignedDay: day,
  provenance: {const StopProvenance.manual()},
);

ItineraryDraft draft({
  TripOrigin? origin = const TripOrigin(latitude: 9, longitude: 9),
  PreferredTravelMode? mode = PreferredTravelMode.car,
  DateTime? startDate,
  bool withoutStartDate = false,
  int durationDays = 1,
  List<DraftStop>? stops,
  List<RequiredTransfer> transfers = const [],
}) => ItineraryDraft.newManual(
  trip: TripConfiguration(
    startDate: withoutStartDate ? null : startDate ?? DateTime(2026, 11, 18),
    durationDays: durationDays,
    availableHoursPerDay: 4,
    origin: origin,
    travelMode: mode,
    requiredTransfers: transfers,
  ),
  stops: stops ?? [stop('a', 0)],
);

class FakeRoutingProvider implements TravelRoutingProvider {
  final List<TravelRouteRequest> requests = [];
  final bool supported;
  final TravelRouteEstimate? Function(TravelRouteRequest request)? response;

  FakeRoutingProvider({this.supported = true, this.response});

  @override
  bool supports(PreferredTravelMode mode) => supported;

  @override
  Future<TravelRouteEstimate?> estimateRoute(TravelRouteRequest request) async {
    requests.add(request);
    return response?.call(request) ??
        TravelRouteEstimate(
          mode: request.mode,
          routeDistanceKm: 12,
          durationMinutes: 35,
          source: 'test router',
          retrievedAt: assessmentNow.subtract(const Duration(minutes: 1)),
          freshUntil: assessmentNow.add(const Duration(hours: 1)),
        );
  }
}

void main() {
  const service = CarsTravelAssessmentService();

  group('CARS travel assessment boundary', () {
    test(
      'reports validated origin-to-first-stop geometry and injected route',
      () async {
        final provider = FakeRoutingProvider();
        final result = await service.assess(
          draft(),
          provider: provider,
          now: assessmentNow,
        );
        final day = result.days.single;
        final leg = day.legs.single;

        expect(leg.kind, TravelLegKind.originToFirstStop);
        expect(leg.straightLineKm, greaterThan(0));
        expect(leg.routeDistanceKm, 12);
        expect(leg.estimatedTravelMinutes, 35);
        expect(day.totalEstimatedTravelMinutes, 35);
        expect(day.availableMinutes, 240);
        expect(
          day.timeCompatibility,
          AvailableTimeCompatibility.withinAvailableTime,
        );
        expect(leg.source, 'test router');
        expect(provider.requests.single.from.latitude, 9);
      },
    );

    test(
      'different tourist-selected origins change straight-line assessment',
      () async {
        final first = await service.assess(draft(), now: assessmentNow);
        final second = await service.assess(
          draft(origin: const TripOrigin(latitude: 8, longitude: 8)),
          now: assessmentNow,
        );
        expect(
          first.days.single.totalStraightLineKm,
          isNot(second.days.single.totalStraightLineKm),
        );
        expect(first.days.single.totalRouteDistanceKm, isNull);
        expect(second.days.single.totalRouteDistanceKm, isNull);
      },
    );

    test(
      'passes every selected travel mode to the provider without speed assumptions',
      () async {
        for (final mode in PreferredTravelMode.values) {
          final provider = FakeRoutingProvider();
          final result = await service.assess(
            draft(mode: mode),
            provider: provider,
            now: assessmentNow,
          );
          expect(provider.requests.single.mode, mode);
          expect(result.days.single.totalEstimatedTravelMinutes, 35);
        }
      },
    );

    test(
      'reports when provider travel time exceeds the configured daily limit',
      () async {
        final provider = FakeRoutingProvider(
          response: (request) => TravelRouteEstimate(
            mode: request.mode,
            routeDistanceKm: 90,
            durationMinutes: 241,
            source: 'test router',
            retrievedAt: assessmentNow,
            freshUntil: assessmentNow.add(const Duration(hours: 1)),
          ),
        );
        final result = await service.assess(
          draft(),
          provider: provider,
          now: assessmentNow,
        );
        expect(
          result.days.single.timeCompatibility,
          AvailableTimeCompatibility.exceedsAvailableTime,
        );
      },
    );

    test(
      'missing provider or mode leaves route time unavailable but keeps geometry',
      () async {
        final noProvider = await service.assess(draft(), now: assessmentNow);
        final noMode = await service.assess(
          draft(mode: null),
          provider: FakeRoutingProvider(),
          now: assessmentNow,
        );
        expect(noProvider.days.single.totalStraightLineKm, greaterThan(0));
        expect(noProvider.days.single.totalRouteDistanceKm, isNull);
        expect(
          noProvider.days.single.timeCompatibility,
          AvailableTimeCompatibility.unknown,
        );
        expect(noMode.days.single.totalEstimatedTravelMinutes, isNull);
      },
    );

    test('missing itinerary date prevents provider request', () async {
      final provider = FakeRoutingProvider();
      final result = await service.assess(
        draft(withoutStartDate: true),
        provider: provider,
        now: assessmentNow,
      );
      expect(provider.requests, isEmpty);
      expect(result.days.single.totalStraightLineKm, greaterThan(0));
      expect(result.days.single.totalEstimatedTravelMinutes, isNull);
      expect(
        result.days.single.timeCompatibility,
        AvailableTimeCompatibility.unknown,
      );
    });

    test('invalid destination and origin coordinates are rejected', () async {
      final invalidDestination = await service.assess(
        draft(stops: [stop('a', 0, latitude: 91)]),
        provider: FakeRoutingProvider(),
        now: assessmentNow,
      );
      final invalidOrigin = await service.assess(
        draft(origin: const TripOrigin(latitude: 9, longitude: 181)),
        provider: FakeRoutingProvider(),
        now: assessmentNow,
      );
      expect(
        invalidDestination.days.single.legs.single.state,
        TravelEstimateState.unavailable,
      );
      expect(invalidDestination.days.single.totalStraightLineKm, isNull);
      expect(
        invalidOrigin.days.single.legs.single.state,
        TravelEstimateState.unavailable,
      );
      expect(
        invalidOrigin.days.single.legs.single.explanation,
        contains('origin coordinates are invalid'),
      );
      expect(
        straightLineDistanceKm(
          const TravelCoordinate(double.nan, 0),
          const TravelCoordinate(0, 0),
        ),
        isNull,
      );
    });

    test(
      'multi-day dates and assignments stay separate; overnight origin is unknown',
      () async {
        final provider = FakeRoutingProvider();
        final result = await service.assess(
          draft(
            durationDays: 2,
            stops: [stop('day-one', 0, day: 1), stop('day-two', 1, day: 2)],
          ),
          provider: provider,
          now: assessmentNow,
        );
        expect(result.days.map((day) => day.dayNumber), [1, 2]);
        expect(result.days[0].itineraryDate, DateTime(2026, 11, 18));
        expect(result.days[1].itineraryDate, DateTime(2026, 11, 19));
        expect(result.days[0].totalEstimatedTravelMinutes, 35);
        expect(
          result.days[1].legs.single.kind,
          TravelLegKind.unknownOvernightStart,
        );
        expect(result.days[1].totalEstimatedTravelMinutes, isNull);
        expect(provider.requests, hasLength(1));
      },
    );

    test(
      'unassigned multi-day stops make overall assessment incomplete',
      () async {
        final result = await service.assess(
          draft(durationDays: 2, stops: [stop('unassigned', 0, day: null)]),
          now: assessmentNow,
        );
        expect(result.hasCompleteRouteData, isFalse);
        expect(result.limitations.single, contains('no assigned trip day'));
      },
    );

    test(
      'ferry transfer remains separate and never calls land router for that leg',
      () async {
        final provider = FakeRoutingProvider();
        final result = await service.assess(
          draft(
            stops: [
              stop('a', 0, latitude: 9.1, longitude: 9.1),
              stop('b', 1, latitude: 10.1, longitude: 10.1),
            ],
            transfers: const [
              RequiredTransfer(
                fromDestinationId: 'a',
                toDestinationId: 'b',
                kind: RequiredTransferKind.ferry,
              ),
            ],
          ),
          provider: provider,
          now: assessmentNow,
        );
        final transfer = result.days.single.legs.last;
        expect(transfer.kind, TravelLegKind.requiredFerryOrBoatTransfer);
        expect(transfer.routeDistanceKm, isNull);
        expect(transfer.estimatedTravelMinutes, isNull);
        expect(
          transfer.explanation,
          contains('schedule and duration are unavailable'),
        );
        expect(provider.requests, hasLength(1)); // only origin to first stop
      },
    );

    test(
      'stale or failed provider data is unavailable for time comparison',
      () async {
        final staleProvider = FakeRoutingProvider(
          response: (request) => TravelRouteEstimate(
            mode: request.mode,
            routeDistanceKm: 1,
            durationMinutes: 10,
            source: 'router',
            retrievedAt: assessmentNow.subtract(const Duration(days: 2)),
            freshUntil: assessmentNow.subtract(const Duration(days: 1)),
          ),
        );
        final stale = await service.assess(
          draft(),
          provider: staleProvider,
          now: assessmentNow,
        );
        expect(stale.days.single.legs.single.state, TravelEstimateState.stale);
        expect(
          stale.days.single.timeCompatibility,
          AvailableTimeCompatibility.unknown,
        );

        final unsupported = await service.assess(
          draft(),
          provider: FakeRoutingProvider(supported: false),
          now: assessmentNow,
        );
        expect(
          unsupported.days.single.legs.single.state,
          TravelEstimateState.unavailable,
        );
      },
    );
  });
}
