import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';
import 'package:samal_nav/screens/tourist_screens/plan_page.dart';
import 'package:samal_nav/services/local_itinerary_draft_store.dart';

const _destinationId = '11111111-1111-4111-8111-111111111111';

void main() {
  late Directory hiveDirectory;
  late Box<String> box;
  late LocalItineraryDraftStore store;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'samal-local-draft-ui-',
    );
    Hive.init(hiveDirectory.path);
  });

  setUp(() async {
    box = await Hive.openBox<String>(LocalItineraryDraftStore.boxName);
    await box.clear();
    store = LocalItineraryDraftStore(box: box);
    await store.saveDraft(_draft());
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('tourist can reopen a saved on-device draft from the planner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlanPage(
          destinationLoader: () async => [_destination()],
          localDraftStore: store,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('open_local_drafts')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Drafts saved on this device'), findsOneWidget);
    expect(
      find.text('Draft · saved only on this device · Feb 10, 2026'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('local_draft_local-ui-draft')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Local draft reopened. Continue editing your plan.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

ItineraryDraft _draft() {
  final record = _destination();
  final timestamp = DateTime.utc(2026, 2, 1);
  return ItineraryDraft(
    id: 'local-ui-draft',
    method: PlanningMethod.manualSelection,
    stage: DraftStage.draftReview,
    createdAt: timestamp,
    updatedAt: DateTime.utc(2026, 2, 10),
    trip: TripConfiguration(
      startDate: DateTime(2026, 2, 10),
      durationDays: 1,
      availableHoursPerDay: 8,
    ),
    stops: [
      DraftStop(
        destinationId: _destinationId,
        destination: DestinationDisplaySnapshot.fromRecord(record),
        selectionOrder: 0,
        provenance: {StopProvenance.manual()},
      ),
    ],
  );
}

DestinationRecord _destination() => const DestinationRecord(
  id: _destinationId,
  name: 'Sample Beach',
  location: 'Samal Island',
  lat: 7.0,
  lng: 125.0,
  category: 'Beach',
  rating: 4.2,
  status: 'active',
  isVerified: true,
  source: DestinationRecordSource.database,
  hasUsableCoordinates: true,
  hasUsableVisitDuration: true,
);
