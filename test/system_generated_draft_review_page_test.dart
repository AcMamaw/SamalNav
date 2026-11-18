import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/manual_selection_moga_adapter.dart';
import 'package:samal_nav/algorithms/moga_engine.dart' as moga;
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';
import 'package:samal_nav/models/price_info.dart';
import 'package:samal_nav/screens/tourist_screens/system_generated_draft_review_page.dart';

const _a = '11111111-1111-4111-8111-111111111111';
const _b = '22222222-2222-4222-8222-222222222222';

void main() {
  testWidgets('MO-GA runs only after explicit action and result needs review', (
    tester,
  ) async {
    var calls = 0;
    ItineraryDraft? returned;
    final draft = _draft(days: const {_a: 2, _b: 1});
    await tester.pumpWidget(
      _host(
        draft,
        onReturned: (value) => returned = value,
        optimizer: (ready) {
          calls++;
          expect(ready.stage, DraftStage.readyForOptimization);
          expect(ready.stops.map((stop) => stop.destinationId).toList(), [
            _a,
            _b,
          ]);
          return const ManualSelectionMogaAdapter().optimize(
            ready,
            configuration: ManualMogaConfiguration(
              populationSize: 8,
              generations: 2,
              randomSeed: 4,
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('Open draft'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(
      find.byKey(const Key('accept_system_optimized_itinerary')),
      findsNothing,
    );
    expect(
      find.textContaining('Tourist-selected starting point: Port'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('optimize_system_draft')));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('Day 1 route'), findsOneWidget);
    expect(find.text('Day 2 route'), findsOneWidget);
    expect(find.textContaining('Day 1'), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('accept_system_optimized_itinerary')),
      findsOneWidget,
    );
    expect(returned, isNull);
    await tester.tap(
      find.byKey(const Key('accept_system_optimized_itinerary')),
    );
    await tester.pumpAndSettle();

    expect(returned, isNotNull);
    expect(returned!.stage, DraftStage.itineraryReview);
    expect(returned!.trip.origin?.label, 'Port');
    expect(returned!.optimizationResult, isA<ManualMogaResult>());
    final multiDayResult = returned!.optimizationResult! as ManualMogaResult;
    expect(multiDayResult.multiDay!.days[0].distanceKm, greaterThan(0));
    expect(multiDayResult.multiDay!.days[1].distanceKm, 0);
    expect(returned!.stops.map((stop) => stop.destinationId).toSet(), {_a, _b});
    expect(
      returned!.stops
          .singleWhere((stop) => stop.destinationId == _a)
          .assignedDay,
      2,
    );
    expect(
      returned!.stops
          .singleWhere((stop) => stop.destinationId == _b)
          .assignedDay,
      1,
    );
    expect(
      returned!.stops.every(
        (stop) =>
            stop.provenance.single.kind ==
            StopProvenanceKind.carsRecommendation,
      ),
      isTrue,
    );
  });

  testWidgets('optimization errors are shown and selections remain available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _draft(),
        optimizer: (_) =>
            throw const DraftOptimizationException('fixture failure'),
      ),
    );
    await tester.tap(find.text('Open draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('optimize_system_draft')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('fixture failure'), findsOneWidget);
    expect(find.byKey(const Key('system_draft_stop_$_a')), findsOneWidget);
    expect(find.byKey(const Key('optimize_system_draft')), findsOneWidget);
    expect(
      find.byKey(const Key('accept_system_optimized_itinerary')),
      findsNothing,
    );
  });

  testWidgets('missing and invalid origins are explained', (tester) async {
    await tester.pumpWidget(_host(_draft(origin: null)));
    await tester.tap(find.text('Open draft'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'No starting point supplied; the first travel leg cannot be estimated.',
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pumpWidget(
      _host(
        _draft(
          origin: const TripOrigin(
            latitude: 91,
            longitude: 126,
            label: 'Invalid',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open draft'));
    await tester.pumpAndSettle();
    expect(find.textContaining('invalid coordinates'), findsOneWidget);
    await tester.tap(find.byKey(const Key('optimize_system_draft')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Trip origin coordinates are invalid.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'incomplete optimizer result is rejected without dropping stops',
    (tester) async {
      await tester.pumpWidget(
        _host(
          _draft(days: const {_a: 1, _b: 2}),
          optimizer: (_) => _result(const [_a]),
        ),
      );
      await tester.tap(find.text('Open draft'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('optimize_system_draft')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('incomplete or inconsistent route'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('system_draft_stop_$_a')), findsOneWidget);
      expect(find.byKey(const Key('system_draft_stop_$_b')), findsOneWidget);
      expect(
        find.byKey(const Key('accept_system_optimized_itinerary')),
        findsNothing,
      );
    },
  );
}

Widget _host(
  ItineraryDraft draft, {
  SystemDraftOptimizer? optimizer,
  ValueChanged<ItineraryDraft>? onReturned,
}) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () async {
          final value = await Navigator.of(context).push<ItineraryDraft>(
            MaterialPageRoute(
              builder: (_) => SystemGeneratedDraftReviewPage(
                draft: draft,
                optimizer: optimizer,
              ),
            ),
          );
          if (value != null) onReturned?.call(value);
        },
        child: const Text('Open draft'),
      ),
    ),
  ),
);

ItineraryDraft _draft({
  Map<String, int> days = const {},
  TripOrigin? origin = const TripOrigin(
    latitude: 7.1,
    longitude: 125.7,
    label: 'Port',
  ),
}) => ItineraryDraft(
  id: 'draft-id',
  method: PlanningMethod.systemGenerated,
  stage: DraftStage.recommendationReview,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  trip: TripConfiguration(
    durationDays: days.isEmpty ? 1 : 2,
    availableHoursPerDay: 8,
    origin: origin,
  ),
  carsRunReference: const CarsRunReference('cars-run'),
  stops: [
    _stop(_a, 'A', 0, days[_a]),
    if (days.isNotEmpty) _stop(_b, 'B', 1, days[_b]),
  ],
);

DraftStop _stop(String id, String name, int order, int? day) => DraftStop(
  destinationId: id,
  destination: DestinationDisplaySnapshot(
    id: id,
    name: name,
    location: 'Samal',
    category: 'Nature',
    categoryId: null,
    latitude: 7 + order * .01,
    longitude: 125 + order * .01,
    visitDurationMinutes: 60,
    entrancePrice: PriceInfo.fromRaw(null),
    recordSource: DestinationRecordSource.database,
    isActive: true,
    isVerified: true,
    hasUsableCoordinates: true,
    hasUsableVisitDuration: true,
  ),
  selectionOrder: order,
  assignedDay: day,
  provenance: {
    StopProvenance(
      kind: StopProvenanceKind.carsRecommendation,
      sourceId: 'cars-run',
      sourceName: 'Context-Aware Recommendation System (CARS)',
    ),
  },
);

ManualMogaResult _result(List<String> ids) => ManualMogaResult(
  draftId: 'draft-id',
  inputDestinationIdsInSelectionOrder: ids,
  oneDay: DraftRouteResult(
    destinationIdsInRouteOrder: ids,
    totalDistanceKm: 1,
    totalTimeHours: 1,
    legDistancesKm: const [],
    legTravelMinutes: const [],
    feasibility: const moga.RouteFeasibility(
      isFeasible: true,
      availableHours: 8,
      requiredHours: 1,
      overByHours: 0,
    ),
    paretoFront: const [],
    selectionPolicy: 'fixture',
  ),
);
