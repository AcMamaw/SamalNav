import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/models/tourist_planning_profile.dart';
import 'package:samal_nav/screens/tourist_screens/planning_preferences_page.dart';
import 'package:samal_nav/services/tourist_planning_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '9a45a12c-20a2-4a1d-b67a-1713b4f8d9bc';

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient(
      'http://127.0.0.1:54321',
      'test-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async => client.dispose());

  testWidgets('loads existing values as unconfirmed and shows blocked fields', (
    tester,
  ) async {
    final service = _FakeProfileService(client, initial: _snapshot());
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Preferences are unconfirmed'), findsOneWidget);
    expect(
      find.textContaining('Persistent confirmation is unavailable'),
      findsOneWidget,
    );
    await _scrollTo(tester, find.textContaining('Budget basis'));
    expect(find.textContaining('Budget basis'), findsOneWidget);
    await _scrollTo(
      tester,
      find.textContaining('Category selection is unavailable'),
    );
    expect(
      find.textContaining('Category selection is unavailable'),
      findsOneWidget,
    );
    await _scrollTo(
      tester,
      find.textContaining('category identifiers (unverified)'),
    );
    expect(
      find.textContaining('category identifiers (unverified)'),
      findsOneWidget,
    );
    await _scrollTo(tester, find.textContaining('separate trip-origin field'));
    expect(find.textContaining('separate trip-origin field'), findsOneWidget);
    await _scrollTo(tester, find.text('Adults (derived): 3'));
    expect(find.text('Adults (derived): 3'), findsOneWidget);
  });

  testWidgets('creates missing profile and leaves it unconfirmed', (
    tester,
  ) async {
    final service = _FakeProfileService(client, initial: null);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(service.createCalls, 1);
    expect(find.text('Preferences are unconfirmed'), findsOneWidget);
    expect(service.lastSnapshot!.preferencesConfirmed, isFalse);
  });

  testWidgets('does not infer adults when subgroup counts are unknown', (
    tester,
  ) async {
    final service = _FakeProfileService(
      client,
      initial: _snapshot(childrenCount: null, eldersCount: null),
    );
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Adults (derived): —'));
    expect(find.text('Adults (derived): —'), findsOneWidget);
    expect(find.byKey(const Key('children_count_field')), findsOneWidget);
    expect(find.byKey(const Key('elders_count_field')), findsOneWidget);
  });

  testWidgets('reviews, saves edits, derives adults, and preserves origin', (
    tester,
  ) async {
    final service = _FakeProfileService(client, initial: _snapshot());
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await _enter(tester, 'budget_min_field', '250');
    await _enter(tester, 'budget_max_field', '1800');
    await _enter(tester, 'available_hours_field', '8');
    await _enter(tester, 'trip_days_field', '3');
    await _enter(tester, 'children_count_field', '2');
    await tester.pump();
    expect(find.text('Adults (derived): 2'), findsOneWidget);

    await _tapReviewButton(tester);
    expect(find.text('Review planning preferences'), findsOneWidget);
    expect(
      find.textContaining('profile will remain unconfirmed after saving'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm_save_preferences')));
    await tester.pumpAndSettle();

    final saved = service.updatedProfile!;
    expect(saved.budgetMin, 250);
    expect(saved.budgetMax, 1800);
    expect(saved.availableHoursPerDay, 8);
    expect(saved.tripDurationDays, 3);
    expect(saved.numberOfTourists, 5);
    expect(saved.childrenCount, 2);
    expect(saved.eldersCount, 1);
    expect(saved.preferredCategories, ['fixture-existing-category-value']);
    expect(saved.currentLat, 12.5);
    expect(saved.currentLng, 125.4);
    expect(service.lastSnapshot!.preferencesConfirmed, isFalse);
    expect(
      find.text('Preferences saved. Profile remains unconfirmed.'),
      findsOneWidget,
    );
  });

  testWidgets('validates budget and hour/day limits before review', (
    tester,
  ) async {
    final service = _FakeProfileService(client, initial: _snapshot());
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await _enter(tester, 'budget_min_field', '900');
    await _enter(tester, 'budget_max_field', '800');
    await _enter(tester, 'available_hours_field', '25');
    await _enter(tester, 'trip_days_field', '31');
    await _tapReviewButton(tester);

    expect(find.text('Review planning preferences'), findsNothing);
    expect(service.updateCalls, 0);
  });

  testWidgets('validates group composition and reports service errors', (
    tester,
  ) async {
    final service = _FakeProfileService(client, initial: _snapshot());
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await _enter(tester, 'group_size_field', '2');
    await _enter(tester, 'children_count_field', '2');
    await _enter(tester, 'elders_count_field', '1');
    await _tapReviewButton(tester);
    expect(find.text('Review planning preferences'), findsNothing);
    expect(
      find.textContaining('cannot exceed the total group size'),
      findsOneWidget,
    );

    service.fetchError = const TouristPlanningProfileAuthenticationException(
      'Sign in before accessing planning preferences.',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlanningPreferencesPage(key: UniqueKey(), service: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Sign in before accessing'), findsOneWidget);
  });

  testWidgets('allows approved travel modes without changing stored origin', (
    tester,
  ) async {
    final service = _FakeProfileService(client, initial: _snapshot());
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('travel_mode_dropdown')));
    await tester.tap(find.byKey(const Key('travel_mode_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('public transportation').last);
    await tester.pumpAndSettle();

    await _tapReviewButton(tester);
    await tester.tap(find.byKey(const Key('confirm_save_preferences')));
    await tester.pumpAndSettle();

    expect(service.updatedProfile!.travelMode, 'public transportation');
    expect(service.updatedProfile!.currentLat, 12.5);
    expect(service.updatedProfile!.currentLng, 125.4);
  });
}

Widget _app(TouristPlanningProfileService service) =>
    MaterialApp(home: PlanningPreferencesPage(service: service));

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final field = find.byKey(Key(key));
  await _scrollTo(tester, field);
  await tester.enterText(field, value);
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find.byType(Scrollable).first,
  );
}

Future<void> _tapReviewButton(WidgetTester tester) async {
  final button = find.byKey(const Key('review_save_preferences'));
  tester.testTextInput.hide();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();

  await _scrollTo(tester, button);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  expect(button, findsOneWidget);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

TouristPlanningProfileSnapshot _snapshot({
  int? childrenCount = 1,
  int? eldersCount = 1,
}) => TouristPlanningProfileSnapshot(
  profile: TouristPlanningProfile.fromJson({
    'id': '2f16d423-e5d3-4e2f-9fa9-85a7bb2ca504',
    'user_id': _userId,
    'budget_min': 100,
    'budget_max': 1500,
    'available_hours_per_day': 9,
    'trip_duration_days': 2,
    'preferred_categories': ['fixture-existing-category-value'],
    'current_lat': 12.5,
    'current_lng': 125.4,
    'travel_mode': 'walking',
    'created_at': '2026-03-12T08:30:00Z',
    'number_of_tourists': 5,
    'children_count': childrenCount,
    'elders_count': eldersCount,
  }),
  preferencesConfirmed: false,
);

class _FakeProfileService extends TouristPlanningProfileService {
  _FakeProfileService(SupabaseClient client, {required this.initial})
    : super(client: client);

  TouristPlanningProfileSnapshot? initial;
  TouristPlanningProfileServiceException? fetchError;
  int createCalls = 0;
  int updateCalls = 0;
  TouristPlanningProfile? updatedProfile;
  TouristPlanningProfileSnapshot? lastSnapshot;

  @override
  Future<TouristPlanningProfileSnapshot?> fetchCurrent() async {
    if (fetchError != null) throw fetchError!;
    return initial;
  }

  @override
  Future<TouristPlanningProfileSnapshot> createIfMissing() async {
    createCalls++;
    lastSnapshot = _snapshot();
    return lastSnapshot!;
  }

  @override
  Future<TouristPlanningProfileSnapshot> updateCurrent(
    TouristPlanningProfile profile, {
    required TouristPlanningProfileValidationPolicy policy,
  }) async {
    updateCalls++;
    final validation = profile.validate(policy);
    if (!validation.isValid) {
      throw TouristPlanningProfileValidationException(validation.errors);
    }
    updatedProfile = profile;
    lastSnapshot = TouristPlanningProfileSnapshot(
      profile: profile,
      preferencesConfirmed: false,
    );
    return lastSnapshot!;
  }
}
