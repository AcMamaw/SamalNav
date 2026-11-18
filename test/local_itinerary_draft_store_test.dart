import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:samal_nav/algorithms/manual_selection_workflow.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';
import 'package:samal_nav/services/local_itinerary_draft_store.dart';

const _idA = '11111111-1111-4111-8111-111111111111';
const _idB = '22222222-2222-4222-8222-222222222222';
const _idC = '33333333-3333-4333-8333-333333333333';

void main() {
  late Directory hiveDirectory;
  late Box<String> draftBox;
  late LocalItineraryDraftStore store;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'samal-local-itinerary-drafts-',
    );
    Hive.init(hiveDirectory.path);
  });

  setUp(() async {
    draftBox = await Hive.openBox<String>(LocalItineraryDraftStore.boxName);
    await draftBox.clear();
    store = LocalItineraryDraftStore(box: draftBox);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'persists and reopens editable draft details after the box is reopened',
    () async {
      final draft = _draft();
      await store.saveDraft(draft, savedAt: DateTime.utc(2026, 2, 3));
      await draftBox.close();

      draftBox = await Hive.openBox<String>(LocalItineraryDraftStore.boxName);
      store = LocalItineraryDraftStore(box: draftBox);
      final reopened = store.readDraft(draft.id);

      expect(reopened, isNotNull);
      expect(reopened!.id, draft.id);
      expect(reopened.stage, DraftStage.draftReview);
      expect(reopened.method, PlanningMethod.manualSelection);
      expect(reopened.trip.durationDays, 2);
      expect(reopened.trip.startDate, DateTime(2026, 2, 10));
      expect(reopened.trip.availableHoursPerDay, 7);
      expect(reopened.trip.budgetMinimum, 100);
      expect(reopened.trip.budgetBasis, BudgetBasis.totalGroup);
      expect(
        reopened.trip.requiredTransfers.single.kind,
        RequiredTransferKind.ferry,
      );
      expect(reopened.trip.origin?.label, 'Hotel');
      expect(reopened.stops.map((stop) => stop.destinationId), [_idA, _idB]);
      expect(reopened.stops.map((stop) => stop.assignedDay), [1, 2]);
      expect(reopened.stops.first.selectedActivityIds, ['activity-a']);
      expect(reopened.stops.first.destination.entrancePrice.rawValue, '250');
    },
  );

  test(
    'editing and saving replaces the same draft without losing stop metadata',
    () async {
      final original = _draft();
      await store.saveDraft(original);
      final edited = const ManualSelectionDraftBuilder().build(
        destinations: [_record(_idA, 'A'), _record(_idB, 'B')],
        daySelections: const [
          [_idB, _idA],
          [],
        ],
        trip: _trip(
          days: 2,
          hours: 8,
          requiredTransfers: original.trip.requiredTransfers,
        ),
        existingDraft: original,
        now: DateTime.utc(2026, 2, 4),
      );

      await store.saveDraft(edited);
      final reopened = store.readDrafts();

      expect(reopened, hasLength(1));
      expect(reopened.single.id, original.id);
      expect(reopened.single.trip.availableHoursPerDay, 8);
      expect(reopened.single.stops.map((stop) => stop.destinationId), [
        _idB,
        _idA,
      ]);
      expect(reopened.single.stops.last.selectedActivityIds, ['activity-a']);
      expect(
        reopened.single.stops.last.provenance,
        original.stops.first.provenance,
      );
    },
  );

  test(
    'round-trips excluded stop state without deleting stored information',
    () async {
      final draft = _draft(excludeFirstStop: true);
      await store.saveDraft(draft);

      final reopened = store.readDraft(draft.id)!;

      expect(reopened.stops.first.isIncluded, isFalse);
      expect(reopened.stops.map((stop) => stop.destinationId), [_idA, _idB]);
    },
  );

  test(
    'save and reopen preserves a revised in-day order and day assignment',
    () async {
      final destinations = [
        _record(_idA, 'A'),
        _record(_idB, 'B'),
        _record(_idC, 'C'),
      ];
      final transfer = const RequiredTransfer(
        fromDestinationId: _idA,
        toDestinationId: _idC,
        kind: RequiredTransferKind.ferry,
      );
      const builder = ManualSelectionDraftBuilder();
      final original = builder.build(
        destinations: destinations,
        daySelections: const [
          [_idA, _idB],
          [_idC],
        ],
        trip: _trip(days: 2, hours: 7, requiredTransfers: [transfer]),
      );
      final dayOne = <String>{_idA, _idB};
      expect(
        moveDestinationWithinDay(dayOne, destinationId: _idB, offset: -1),
        isTrue,
      );
      final reordered = builder.build(
        destinations: destinations,
        daySelections: [
          dayOne.toList(),
          const [_idC],
        ],
        trip: original.trip,
        existingDraft: original,
      );
      await store.saveDraft(reordered);
      await draftBox.close();

      draftBox = await Hive.openBox<String>(LocalItineraryDraftStore.boxName);
      store = LocalItineraryDraftStore(box: draftBox);
      final reopened = store.readDraft(reordered.id)!;

      expect(reopened.stops.map((stop) => stop.destinationId), [
        _idB,
        _idA,
        _idC,
      ]);
      expect(reopened.stops.map((stop) => stop.assignedDay), [1, 1, 2]);
      expect(reopened.trip.requiredTransfers.single.fromDestinationId, _idA);
      expect(reopened.trip.requiredTransfers.single.toDestinationId, _idC);
    },
  );

  test(
    'uses a separate box and leaves existing synced cache entries intact',
    () async {
      final syncedBox = await Hive.openBox<String>(
        'samal_nav_synced_records_v1',
      );
      const existingSnapshot =
          '{"syncedAt":"2026-01-01T00:00:00Z","data":{"id":"keep"}}';
      await syncedBox.put('existing-record', existingSnapshot);

      await store.saveDraft(_draft());

      expect(syncedBox.get('existing-record'), existingSnapshot);
      expect(draftBox.get('existing-record'), isNull);
      expect(store.readDrafts(), hasLength(1));
    },
  );

  test('does not discard an unsupported future format record', () async {
    final raw = jsonEncode({
      'formatVersion': 99,
      'storageState': 'localDraft',
      'draft': {},
    });
    await draftBox.put('draft:future-record', raw);

    expect(store.readDrafts, throwsFormatException);
    expect(draftBox.get('draft:future-record'), raw);
  });

  test('refuses saved or optimized records without changing the box', () async {
    final draft = _draft();
    final savedStage = ItineraryDraft(
      id: draft.id,
      method: draft.method,
      stage: DraftStage.itineraryReview,
      createdAt: draft.createdAt,
      updatedAt: draft.updatedAt,
      trip: draft.trip,
      stops: draft.stops,
    );

    await expectLater(store.saveDraft(savedStage), throwsStateError);
    expect(draftBox.isEmpty, isTrue);
  });
}

ItineraryDraft _draft({bool excludeFirstStop = false}) {
  final trip = _trip(
    days: 2,
    hours: 7,
    requiredTransfers: const [
      RequiredTransfer(
        fromDestinationId: _idA,
        toDestinationId: _idB,
        kind: RequiredTransferKind.ferry,
      ),
    ],
  );
  final first = _record(_idA, 'A');
  final second = _record(_idB, 'B');
  final timestamp = DateTime.utc(2026, 2, 1);
  return ItineraryDraft(
    id: 'draft-local-test',
    method: PlanningMethod.manualSelection,
    stage: DraftStage.draftReview,
    createdAt: timestamp,
    updatedAt: timestamp,
    trip: trip,
    stops: [
      DraftStop(
        destinationId: _idA,
        destination: DestinationDisplaySnapshot.fromRecord(first),
        selectionOrder: 0,
        assignedDay: 1,
        provenance: {StopProvenance.manual()},
        selectedActivityIds: const ['activity-a'],
        isIncluded: !excludeFirstStop,
      ),
      DraftStop(
        destinationId: _idB,
        destination: DestinationDisplaySnapshot.fromRecord(second),
        selectionOrder: 1,
        assignedDay: 2,
        provenance: {StopProvenance.manual()},
      ),
    ],
  );
}

TripConfiguration _trip({
  required int days,
  required int hours,
  List<RequiredTransfer> requiredTransfers = const [],
}) => TripConfiguration(
  startDate: DateTime(2026, 2, 10),
  durationDays: days,
  availableHoursPerDay: hours,
  budgetMinimum: 100,
  budgetMaximum: 900,
  budgetBasis: BudgetBasis.totalGroup,
  currency: 'PHP',
  totalGroupSize: 4,
  childrenCount: 1,
  eldersCount: 1,
  origin: const TripOrigin(latitude: 7.1, longitude: 125.7, label: 'Hotel'),
  travelMode: PreferredTravelMode.car,
  requiredTransfers: requiredTransfers,
);

DestinationRecord _record(String id, String name) => DestinationRecord(
  id: id,
  name: name,
  location: 'Samal Island',
  lat: 7.0,
  lng: 125.0,
  category: 'Beach',
  rating: 4.2,
  status: 'active',
  isVerified: true,
  rawEntranceFee: '250',
  averageStayMinutes: 75,
  source: DestinationRecordSource.database,
  hasUsableCoordinates: true,
  hasUsableVisitDuration: true,
);
