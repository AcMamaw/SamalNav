import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:samal_nav/models/tourist_planning_profile.dart';
import 'package:samal_nav/services/tourist_planning_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '9a45a12c-20a2-4a1d-b67a-1713b4f8d9bc';
const _profileId = '2f16d423-e5d3-4e2f-9fa9-85a7bb2ca504';
const _otherUserId = 'af346923-d4e5-4a55-9037-cb0eddf07fd0';

void main() {
  late _MockHttpClient httpClient;
  late SupabaseClient supabase;
  late TouristPlanningProfileService service;

  setUp(() async {
    httpClient = _MockHttpClient((request) async {
      if (request.url.path == '/auth/v1/user') {
        return _Reply(200, _userJson());
      }
      throw StateError('Unexpected local mock request path.');
    });
    supabase = SupabaseClient(
      'http://127.0.0.1:54321',
      'test-anon-key',
      httpClient: httpClient,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await supabase.auth.setSession(
      'test-refresh-token',
      accessToken: _testJwt(),
    );
    httpClient.clearRequests();
    service = TouristPlanningProfileService(client: supabase);
  });

  tearDown(() async {
    await supabase.dispose();
    httpClient.close();
  });

  test(
    'fetch returns only the session user profile and parses database fields',
    () async {
      httpClient.handler = (_) async => _Reply(200, [_profileJson()]);

      final snapshot = await service.fetchCurrent();

      expect(snapshot, isNotNull);
      expect(snapshot!.profile.id, _profileId);
      expect(snapshot.profile.userId, _userId);
      expect(snapshot.profile.budgetMin, 0.0);
      expect(snapshot.profile.budgetMax, 5000.0);
      expect(snapshot.profile.availableHoursPerDay, 9);
      expect(snapshot.profile.tripDurationDays, 1);
      expect(snapshot.profile.preferredCategories, isEmpty);
      expect(snapshot.profile.currentLat, isNull);
      expect(snapshot.profile.currentLng, isNull);
      expect(snapshot.profile.travelMode, 'walking');
      expect(
        snapshot.profile.createdAt,
        DateTime.parse('2026-03-12T08:30:00Z'),
      );
      expect(snapshot.profile.numberOfTourists, 1);
      expect(snapshot.profile.childrenCount, 0);
      expect(snapshot.profile.eldersCount, 0);
      expect(snapshot.preferencesConfirmed, isFalse);

      final request = httpClient.requests.single;
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/tourist_details');
      expect(request.url.queryParameters['user_id'], 'eq.$_userId');
    },
  );

  test(
    'fetch returns null for an empty result, not for request errors',
    () async {
      httpClient.handler = (_) async => _Reply(200, []);

      expect(await service.fetchCurrent(), isNull);
      expect(httpClient.requests.single.method, 'GET');
    },
  );

  test('create inserts only the session-derived user_id', () async {
    var getCount = 0;
    httpClient.handler = (request) async {
      if (request.method == 'GET') {
        getCount++;
        return _Reply(200, []);
      }
      if (request.method == 'POST') {
        return _Reply(201, _profileJson());
      }
      throw StateError('Unexpected local mock request method.');
    };

    final snapshot = await service.createIfMissing();

    expect(snapshot.profile.userId, _userId);
    expect(snapshot.preferencesConfirmed, isFalse);
    expect(getCount, 1);
    final insert = httpClient.requests.last;
    expect(insert.method, 'POST');
    expect(insert.url.path, '/rest/v1/tourist_details');
    expect(jsonDecode(insert.body), {'user_id': _userId});
  });

  test(
    'create reloads the profile after a duplicate user_id response',
    () async {
      var getCount = 0;
      httpClient.handler = (request) async {
        if (request.method == 'GET') {
          getCount++;
          return _Reply(200, getCount == 1 ? [] : [_profileJson()]);
        }
        if (request.method == 'POST') {
          return _Reply(409, {
            'code': '23505',
            'message': 'duplicate key value violates unique constraint',
            'details': null,
            'hint': null,
          });
        }
        throw StateError('Unexpected local mock request method.');
      };

      final snapshot = await service.createIfMissing();

      expect(snapshot.profile.id, _profileId);
      expect(snapshot.preferencesConfirmed, isFalse);
      expect(getCount, 2);
      expect(httpClient.requests.map((request) => request.method), [
        'GET',
        'POST',
        'GET',
      ]);
    },
  );

  test(
    'update writes editable fields through the authenticated owner filter',
    () async {
      httpClient.handler = (_) async => _Reply(200, _profileJson());

      final snapshot = await service.updateCurrent(
        _profile(),
        policy: _testPolicy(),
      );

      expect(snapshot.profile.userId, _userId);
      expect(snapshot.preferencesConfirmed, isFalse);
      final request = httpClient.requests.single;
      expect(request.method, 'PATCH');
      expect(request.url.path, '/rest/v1/tourist_details');
      expect(request.url.queryParameters['user_id'], 'eq.$_userId');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['budget_min'], 0.0);
      expect(body['budget_max'], 5000.0);
      expect(body.containsKey('user_id'), isFalse);
      expect(body.containsKey('id'), isFalse);
    },
  );

  test('update rejects another user before sending an HTTP request', () async {
    final profile = _profile(userId: _otherUserId);

    await expectLater(
      service.updateCurrent(profile, policy: _testPolicy()),
      throwsA(isA<TouristPlanningProfileServiceException>()),
    );
    expect(httpClient.requests, isEmpty);
  });

  test('unauthenticated access throws without an HTTP request', () async {
    final unauthenticatedClient = SupabaseClient(
      'http://127.0.0.1:54321',
      'test-anon-key',
      httpClient: httpClient,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(unauthenticatedClient.dispose);
    final unauthenticatedService = TouristPlanningProfileService(
      client: unauthenticatedClient,
    );

    await expectLater(
      unauthenticatedService.fetchCurrent(),
      throwsA(isA<TouristPlanningProfileAuthenticationException>()),
    );
    expect(httpClient.requests, isEmpty);
  });

  test(
    'RLS or permission errors propagate instead of becoming no profile',
    () async {
      httpClient.handler = (_) async => _Reply(403, {
        'code': '42501',
        'message': 'permission denied by row-level security policy',
        'details': null,
        'hint': null,
      });

      await expectLater(
        service.fetchCurrent(),
        throwsA(isA<PostgrestException>()),
      );
      expect(httpClient.requests.single.method, 'GET');
    },
  );

  test('network errors propagate instead of becoming no profile', () async {
    httpClient.handler = (_) async =>
        throw const SocketException('Synthetic transport failure.');

    await expectLater(service.fetchCurrent(), throwsA(isA<SocketException>()));
    expect(httpClient.requests, isNotEmpty);
    expect(
      httpClient.requests.every((request) => request.method == 'GET'),
      isTrue,
    );
  });
}

TouristPlanningProfileValidationPolicy _testPolicy() =>
    TouristPlanningProfileValidationPolicy(
      // Synthetic values for this test fixture only; these are not project
      // validation decisions or deployed category/travel-mode values.
      maximumHoursPerDay: 24,
      maximumTripDays: 30,
      validCategoryCodes: {'test-category'},
      supportedTravelModes: {'walking'},
    );

TouristPlanningProfile _profile({String userId = _userId}) =>
    TouristPlanningProfile.fromJson(_profileJson(userId: userId));

Map<String, dynamic> _profileJson({String userId = _userId}) => {
  'id': _profileId,
  'user_id': userId,
  'budget_min': 0,
  'budget_max': 5000,
  'available_hours_per_day': 9,
  'trip_duration_days': 1,
  'preferred_categories': <String>[],
  'current_lat': null,
  'current_lng': null,
  'travel_mode': 'walking',
  'created_at': '2026-03-12T08:30:00Z',
  'number_of_tourists': 1,
  'children_count': 0,
  'elders_count': 0,
};

Map<String, dynamic> _userJson() => {
  'id': _userId,
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': 'synthetic-user@example.invalid',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'created_at': '2026-03-12T08:00:00Z',
};

String _testJwt() {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final signature = base64Url
      .encode(utf8.encode('synthetic-test-signature'))
      .replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${encode({'sub': _userId, 'role': 'authenticated', 'aud': 'authenticated', 'iat': now, 'exp': now + 3600})}.$signature';
}

class _Reply {
  final int statusCode;
  final Object body;

  const _Reply(this.statusCode, this.body);
}

typedef _RequestHandler = Future<_Reply> Function(http.Request request);

class _MockHttpClient extends http.BaseClient {
  _RequestHandler handler;
  final List<http.Request> requests = [];

  _MockHttpClient(this.handler);

  void clearRequests() => requests.clear();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest baseRequest) async {
    final bytes = await baseRequest.finalize().toBytes();
    final request = http.Request(baseRequest.method, baseRequest.url)
      ..headers.addAll(baseRequest.headers)
      ..bodyBytes = bytes;
    requests.add(request);
    final reply = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(reply.body))),
      reply.statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      request: request,
    );
  }
}
