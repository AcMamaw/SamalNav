import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/screens/tourist_screens/favorite_page.dart'
    show FavoriteItem;
import 'package:samal_nav/screens/tourist_screens/home_page.dart' show Place;
import 'package:samal_nav/screens/tourist_screens/map_page.dart' show MapPlace;
import 'package:samal_nav/services/destination_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _categoryId = 'f70e425a-2af5-4f3f-8c31-ec8dbe4c0b89';

void main() {
  group('DestinationRecord rating data', () {
    test('preserves a valid verified rating and available provenance', () {
      final destination = DestinationRecord.fromJson({
        ..._destinationJson(),
        'rating_average': '4.25',
        'rating_is_verified': true,
        'rating_source': 'official directory',
        'rating_retrieved_at': '2026-10-01T08:00:00Z',
        'rating_fresh_until': '2026-11-01T08:00:00Z',
      }, source: DestinationRecordSource.database);

      expect(destination.rating, 4.25);
      expect(destination.ratingDataState, DestinationRatingDataState.available);
      expect(destination.availableRating, 4.25);
      expect(destination.ratingSource, 'official directory');
      expect(destination.ratingRetrievedAt, DateTime.parse('2026-10-01T08:00:00Z'));
      expect(destination.ratingFreshUntil, DateTime.parse('2026-11-01T08:00:00Z'));
    });

    test('preserves explicit zero as a valid rating', () {
      final destination = DestinationRecord.fromJson({
        ..._destinationJson(),
        'rating_average': 0,
        'rating_is_verified': true,
      }, source: DestinationRecordSource.database);

      expect(destination.rating, 0);
      expect(destination.availableRating, 0);
    });

    test('null and absent rating values are unavailable', () {
      final explicitNull = DestinationRecord.fromJson({
        ..._destinationJson(),
        'rating_average': null,
      });
      final missing = Map<String, dynamic>.from(_destinationJson())
        ..remove('rating_average');

      final absent = DestinationRecord.fromJson(missing);
      expect(explicitNull.rating, isNull);
      expect(explicitNull.ratingDataState, DestinationRatingDataState.missing);
      expect(explicitNull.availableRating, isNull);
      expect(absent.rating, isNull);
      expect(absent.ratingDataState, DestinationRatingDataState.missing);
    });

    test('malformed, non-finite, and out-of-range values are unavailable', () {
      for (final invalid in ['not a rating', double.nan, double.infinity, -0.1, 5.1]) {
        final destination = DestinationRecord.fromJson({
          ..._destinationJson(),
          'rating_average': invalid,
          'rating_is_verified': true,
        }, source: DestinationRecordSource.database);

        expect(destination.rating, isNull, reason: '$invalid');
        expect(destination.ratingDataState, DestinationRatingDataState.invalid);
        expect(destination.availableRating, isNull);
      }
    });

    test('valid but unverified values are retained but unavailable to UI', () {
      final destination = DestinationRecord.fromJson({
        ..._destinationJson(),
        'rating_average': 4.5,
      }, source: DestinationRecordSource.database);

      expect(destination.rating, 4.5);
      expect(destination.ratingVerification, DestinationRatingVerification.unknown);
      expect(destination.availableRating, isNull);
    });

    test('fallback ratings are not treated as available public ratings', () {
      const destination = DestinationRecord(
        id: 'fallback',
        name: 'Sample',
        location: 'Samal Island',
        lat: 7,
        lng: 125,
        category: 'Beach',
        rating: 4.5,
        status: 'active',
        isVerified: true,
        source: DestinationRecordSource.fallback,
      );

      expect(destination.rating, 4.5);
      expect(destination.availableRating, isNull);
    });

    test('home and map consumers hide a valid but unverified value', () {
      final destination = DestinationRecord.fromJson({
        ..._destinationJson(),
        'rating_average': 4.5,
      }, source: DestinationRecordSource.database);

      final homePlace = Place.fromRecord(destination);
      final mapPlace = MapPlace.fromRecord(destination);
      expect(homePlace.rating, isNull);
      expect(homePlace.ratingAvailable, isFalse);
      expect(mapPlace.rating, isNull);
    });

    test('verified rating remains available to home and map consumers', () {
      final destination = DestinationRecord.fromJson({
        ..._destinationJson(),
        'rating_is_verified': true,
      }, source: DestinationRecordSource.database);

      expect(Place.fromRecord(destination).rating, 4.5);
      expect(MapPlace.fromRecord(destination).rating, 4.5);
    });

    test('favorite rating snapshots reject missing and invalid values', () {
      expect(FavoriteItem.parseValidRating(null), isNull);
      expect(FavoriteItem.parseValidRating('unrated'), isNull);
      expect(FavoriteItem.parseValidRating(-1), isNull);
      expect(FavoriteItem.parseValidRating(5.1), isNull);
      expect(FavoriteItem.parseValidRating(0), 0);
      expect(FavoriteItem.parseValidRating('4.25'), 4.25);

      final savedSnapshot = FavoriteItem(
        id: 'local-favorite',
        name: 'Favorite',
        location: 'Samal Island',
        rating: 4.25,
        category: 'Beach',
        gradient: const [],
      );
      expect(savedSnapshot.rating, 4.25);
      expect(savedSnapshot.ratingAvailable, isFalse);
    });
  });

  group('DestinationRecord category ID', () {
    test('parses valid UUID and preserves original text category', () {
      final destination = DestinationRecord.fromJson({
        ..._destinationJson(),
        'category_id': _categoryId,
        'category': 'Falls',
      });

      expect(destination.categoryId, _categoryId);
      expect(destination.category, 'Falls');
    });

    test('missing and explicit null UUIDs remain null', () {
      final missing = DestinationRecord.fromJson(_destinationJson());
      final explicitNull = DestinationRecord.fromJson({
        ..._destinationJson(),
        'category_id': null,
      });

      expect(missing.categoryId, isNull);
      expect(explicitNull.categoryId, isNull);
    });

    test('rejects malformed non-null UUIDs', () {
      expect(
        () => DestinationRecord.fromJson({
          ..._destinationJson(),
          'category_id': 'not-a-uuid',
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('category_id'),
          ),
        ),
      );
    });

    test('serializes category ID and original category with database keys', () {
      final destination = DestinationRecord.fromJson({
        ..._destinationJson(),
        'category_id': _categoryId,
        'category': 'Falls',
      });

      final json = destination.toJson();
      expect(json['category_id'], _categoryId);
      expect(json['category'], 'Falls');
    });

    test('serializes a null category ID without inventing a value', () {
      final destination = DestinationRecord.fromJson(_destinationJson());

      expect(destination.toJson(), containsPair('category_id', isNull));
    });

    test('existing constructor remains compatible with no category ID', () {
      const destination = DestinationRecord(
        id: 'sample-destination',
        name: 'Sample destination',
        location: 'Samal Island',
        lat: 7.0,
        lng: 125.0,
        category: 'Historical',
        rating: 4.0,
        status: 'active',
        isVerified: false,
      );

      expect(destination.categoryId, isNull);
      expect(destination.category, 'Historical');
    });
  });

  group('DestinationService.getAll category IDs', () {
    test(
      'parses category_id from the unrestricted destinations SELECT',
      () async {
        late Uri requestedUri;
        final client = _client((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode([
              {
                ..._destinationJson(),
                'category_id': _categoryId,
                'category': 'Falls',
              },
            ]),
            200,
            headers: const {'content-type': 'application/json'},
            request: request,
          );
        });

        try {
          final records = await DestinationService.getAll(
            client: client,
            forceRefresh: true,
          );

          expect(requestedUri.path, '/rest/v1/destinations');
          expect(requestedUri.queryParameters['select'], '*');
          expect(records, hasLength(1));
          expect(records.single.categoryId, _categoryId);
          expect(records.single.category, 'Falls');
          expect(records.single.source, DestinationRecordSource.database);
        } finally {
          await client.dispose();
        }
      },
    );

    test(
      'falls back after a failed request and keeps category IDs unset',
      () async {
        final client = _client(
          (request) async => http.Response(
            jsonEncode({'message': 'Request failed'}),
            500,
            headers: const {'content-type': 'application/json'},
            request: request,
          ),
        );

        try {
          final records = await DestinationService.getAll(
            client: client,
            forceRefresh: true,
          );

          expect(records, isNotEmpty);
          expect(
            records.every((destination) => destination.categoryId == null),
            isTrue,
          );
          expect(
            records.every(
              (destination) =>
                  destination.source == DestinationRecordSource.fallback,
            ),
            isTrue,
          );
        } finally {
          await client.dispose();
        }
      },
    );
  });
}

SupabaseClient _client(Future<http.Response> Function(http.Request) handler) =>
    SupabaseClient(
      'http://127.0.0.1:54321',
      'test-anon-key',
      httpClient: MockClient(handler),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

Map<String, dynamic> _destinationJson() => {
  'id': 'destination-1',
  'name': 'Test destination',
  'location': 'Samal Island',
  'lat': 7.0,
  'lng': 125.0,
  'category': 'Beach',
  'rating_average': 4.5,
  'status': 'active',
  'is_verified': false,
};
