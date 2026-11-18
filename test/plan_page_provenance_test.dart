import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/screens/tourist_screens/plan_page.dart';

void main() {
  testWidgets('labels bundled fallback destinations as unverified samples', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlanPage(
          destinationLoader: () async => [
            _destination(source: DestinationRecordSource.fallback),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const Key('fallback_destination_notice')),
      findsOneWidget,
    );
    expect(
      find.textContaining('1 bundled offline sample destination.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('not been checked against the current database'),
      findsOneWidget,
    );
    expect(
      find.textContaining('cannot be optimized with MO-GA'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('does not label database destinations as offline samples', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlanPage(
          destinationLoader: () async => [
            _destination(source: DestinationRecordSource.database),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('fallback_destination_notice')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

DestinationRecord _destination({required DestinationRecordSource source}) =>
    DestinationRecord(
      id: source == DestinationRecordSource.fallback
          ? 'fb-sample'
          : '11111111-1111-4111-8111-111111111111',
      name: 'Sample Beach',
      location: 'Samal Island',
      lat: 7.0,
      lng: 125.0,
      category: 'Beach',
      rating: 4.0,
      status: 'active',
      isVerified: true,
      source: source,
      hasUsableCoordinates: true,
      hasUsableVisitDuration: true,
    );
