import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/screens/tourist_screens/plan_page.dart';

const _hagimitId = '11111111-1111-4111-8111-111111111111';
const _maximaId = '22222222-2222-4222-8222-222222222222';
const _ligidId = '33333333-3333-4333-8333-333333333333';

void main() {
  testWidgets('reorder controls expose boundaries and move selected stops', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlanPage(
          package: 'Forest Trek & Falls',
          destinationLoader: () async => [
            _destination(_hagimitId, 'Hagimit Falls'),
            _destination(_maximaId, 'Maxima Aqua Fun'),
            _destination(_ligidId, 'Ligid Cave'),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final firstUp = tester.widget<IconButton>(
      find.byKey(const Key('reorder_up_$_hagimitId')),
    );
    final lastDown = tester.widget<IconButton>(
      find.byKey(const Key('reorder_down_$_ligidId')),
    );
    final middleUp = tester.widget<IconButton>(
      find.byKey(const Key('reorder_up_$_maximaId')),
    );
    final middleDown = tester.widget<IconButton>(
      find.byKey(const Key('reorder_down_$_maximaId')),
    );
    expect(firstUp.onPressed, isNull);
    expect(lastDown.onPressed, isNull);
    expect(middleUp.onPressed, isNotNull);
    expect(middleDown.onPressed, isNotNull);
    expect(middleUp.tooltip, 'Move Maxima Aqua Fun earlier');
    expect(find.text('Itinerary order'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('reorder_up_$_maximaId')));
    await tester.tap(find.byKey(const Key('reorder_up_$_maximaId')));
    await tester.pump(const Duration(milliseconds: 300));

    final maximaTop = tester.getTopLeft(
      find.byKey(const Key('ordered_stop_$_maximaId')),
    );
    final hagimitTop = tester.getTopLeft(
      find.byKey(const Key('ordered_stop_$_hagimitId')),
    );
    final ligidTop = tester.getTopLeft(
      find.byKey(const Key('ordered_stop_$_ligidId')),
    );
    expect(maximaTop.dy, lessThan(hagimitTop.dy));
    expect(hagimitTop.dy, lessThan(ligidTop.dy));
    expect(find.text('Review manual draft'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

DestinationRecord _destination(String id, String name) => DestinationRecord(
  id: id,
  name: name,
  location: 'Samal Island',
  lat: 7.0,
  lng: 125.0,
  category: 'Falls',
  rating: 4,
  status: 'active',
  isVerified: true,
  source: DestinationRecordSource.database,
  hasUsableCoordinates: true,
  hasUsableVisitDuration: true,
);
