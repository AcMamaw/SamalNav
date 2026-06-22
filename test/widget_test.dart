// This is a basic Flutter widget test for Samal Nav.

import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/main.dart';

void main() {
  testWidgets('SamalNav app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SamalNavApp());
    
    // Wait for the slide and fade animations to finish loading
    await tester.pumpAndSettle();

    // Verify that the landing page loads by finding the Hero Text and Button
    expect(find.text('Explore\nSamal\nIsland'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
