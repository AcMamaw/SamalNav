import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:samal_nav/models/itinerary_draft.dart';
import 'package:samal_nav/services/open_weather_map_service.dart';

void main() {
  final now = DateTime.utc(2026, 5, 1, 0);
  final origin = const WeatherLocation(
    latitude: 7.123,
    longitude: 125.456,
    label: 'Tourist-selected port',
  );

  group('OpenWeatherMapService', () {
    test(
      'requests selected coordinates and preserves forecast provenance',
      () async {
        Uri? requestedUri;
        final service = OpenWeatherMapService(
          apiKey: 'test-only-key',
          clock: () => now,
          client: MockClient((request) async {
            requestedUri = request.url;
            return http.Response(
              _validResponse([_point(now.add(const Duration(hours: 3)))]),
              200,
            );
          }),
        );

        final result = await service.forecast(
          location: origin,
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 1),
        );

        expect(requestedUri!.host, 'api.openweathermap.org');
        expect(requestedUri!.path, '/data/2.5/forecast');
        expect(requestedUri!.queryParameters['lat'], '7.123');
        expect(requestedUri!.queryParameters['lon'], '125.456');
        expect(requestedUri!.queryParameters['units'], 'metric');
        expect(result.requestedLocation, same(origin));
        expect(result.providerLatitude, 7.1);
        expect(result.providerTimezoneOffsetSeconds, 28800);
        expect(result.units, WeatherUnits.metric);
        expect(result.retrievedAt, now);
        expect(result.coverage, WeatherForecastCoverage.available);
        expect(
          result.points.single.forecastAtUtc,
          now.add(const Duration(hours: 3)),
        );
        expect(result.points.single.temperature, 27.5);
        expect(result.points.single.rainLastThreeHoursMm, 1.2);
        final raw = result.toCarsWeatherObservation();
        expect(raw['provider'], contains('OpenWeatherMap'));
        expect(raw['coverage'], 'available');
        expect(raw.containsKey('score'), isFalse);
        service.close();
      },
    );

    test('uses selected trip origin and trip date range without GPS', () async {
      Uri? requestedUri;
      final service = OpenWeatherMapService(
        apiKey: 'test-only-key',
        clock: () => now,
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            _validResponse([
              _point(now.add(const Duration(hours: 3))),
              _point(now.add(const Duration(days: 1, hours: 3))),
            ]),
            200,
          );
        }),
      );
      final trip = TripConfiguration(
        startDate: DateTime(2026, 5, 1),
        durationDays: 2,
        availableHoursPerDay: 8,
        origin: const TripOrigin(latitude: 7.123, longitude: 125.456),
      );

      final result = await service.forecastForTrip(trip);

      expect(requestedUri!.queryParameters['lat'], '7.123');
      expect(requestedUri!.queryParameters['lon'], '125.456');
      expect(result.requestedEndDate, DateTime.utc(2026, 5, 2));
      expect(result.coverage, WeatherForecastCoverage.available);
      service.close();
    });

    test(
      'marks missing provider dates as partial and exposes uncovered dates',
      () async {
        final service = OpenWeatherMapService(
          apiKey: 'test-only-key',
          clock: () => now,
          client: MockClient(
            (_) async => http.Response(
              _validResponse([_point(now.add(const Duration(hours: 3)))]),
              200,
            ),
          ),
        );

        final result = await service.forecast(
          location: origin,
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 8),
        );

        expect(result.coverage, WeatherForecastCoverage.partial);
        expect(result.uncoveredDates, contains(DateTime.utc(2026, 5, 8)));
        expect(result.toCarsWeatherObservation()['coverage'], 'partial');
        service.close();
      },
    );

    test('classifies forecast timestamps in the past as stale', () async {
      final service = OpenWeatherMapService(
        apiKey: 'test-only-key',
        clock: () => now,
        client: MockClient(
          (_) async => http.Response(
            _validResponse([_point(now.subtract(const Duration(hours: 3)))]),
            200,
          ),
        ),
      );

      final result = await service.forecast(
        location: origin,
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 1),
      );

      expect(result.coverage, WeatherForecastCoverage.stale);
      expect(result.isStale, isTrue);
      expect(result.points.single.isExpiredAt(now), isTrue);
      service.close();
    });

    test('reports missing credentials without making a request', () async {
      var requested = false;
      final service = OpenWeatherMapService(
        apiKey: '  ',
        clock: () => now,
        client: MockClient((_) async {
          requested = true;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        service.forecast(
          location: origin,
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 1),
        ),
        throwsA(
          isA<WeatherProviderException>().having(
            (error) => error.kind,
            'kind',
            WeatherProviderFailureKind.missingCredentials,
          ),
        ),
      );
      expect(requested, isFalse);
      service.close();
    });

    test('reports missing location and dates for trip requests', () async {
      final service = OpenWeatherMapService(
        apiKey: 'test-only-key',
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      await expectLater(
        service.forecastForTrip(
          TripConfiguration(durationDays: 1, availableHoursPerDay: 8),
        ),
        throwsA(
          isA<WeatherProviderException>().having(
            (error) => error.kind,
            'kind',
            WeatherProviderFailureKind.missingLocation,
          ),
        ),
      );
      await expectLater(
        service.forecastForTrip(
          TripConfiguration(
            durationDays: 1,
            availableHoursPerDay: 8,
            origin: const TripOrigin(latitude: 7, longitude: 125),
          ),
        ),
        throwsA(
          isA<WeatherProviderException>().having(
            (error) => error.kind,
            'kind',
            WeatherProviderFailureKind.missingTripDates,
          ),
        ),
      );
      service.close();
    });

    test('invalid coordinates are rejected before network access', () async {
      var requested = false;
      final service = OpenWeatherMapService(
        apiKey: 'test-only-key',
        client: MockClient((_) async {
          requested = true;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        service.forecast(
          location: const WeatherLocation(latitude: 91, longitude: 125),
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 1),
        ),
        throwsArgumentError,
      );
      expect(requested, isFalse);
      service.close();
    });

    test('maps invalid credentials and provider rate limits', () async {
      for (final status in [401, 403, 429]) {
        final service = OpenWeatherMapService(
          apiKey: 'test-only-key',
          client: MockClient((_) async => http.Response('{}', status)),
        );
        await expectLater(
          service.forecast(
            location: origin,
            startDate: DateTime(2026, 5, 1),
            endDate: DateTime(2026, 5, 1),
          ),
          throwsA(
            isA<WeatherProviderException>().having(
              (error) => error.kind,
              'kind',
              status == 429
                  ? WeatherProviderFailureKind.rateLimited
                  : WeatherProviderFailureKind.invalidCredentials,
            ),
          ),
        );
        service.close();
      }
    });

    test(
      'handles malformed JSON and missing required response fields',
      () async {
        final bodies = [
          'not json',
          jsonEncode({'cod': '200', 'list': []}),
          _validResponse([
            _point(now.add(const Duration(hours: 3)))..remove('main'),
          ]),
        ];
        for (final body in bodies) {
          final service = OpenWeatherMapService(
            apiKey: 'test-only-key',
            client: MockClient((_) async => http.Response(body, 200)),
          );
          await expectLater(
            service.forecast(
              location: origin,
              startDate: DateTime(2026, 5, 1),
              endDate: DateTime(2026, 5, 1),
            ),
            throwsA(
              isA<WeatherProviderException>().having(
                (error) => error.kind,
                'kind',
                WeatherProviderFailureKind.malformedResponse,
              ),
            ),
          );
          service.close();
        }
      },
    );

    test('converts network errors and timeouts into safe failures', () async {
      final networkService = OpenWeatherMapService(
        apiKey: 'test-only-key',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(
        networkService.forecast(
          location: origin,
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 1),
        ),
        throwsA(
          isA<WeatherProviderException>().having(
            (error) => error.kind,
            'kind',
            WeatherProviderFailureKind.network,
          ),
        ),
      );
      networkService.close();

      final pending = Completer<http.Response>();
      final timeoutService = OpenWeatherMapService(
        apiKey: 'test-only-key',
        timeout: const Duration(milliseconds: 5),
        client: MockClient((_) => pending.future),
      );
      await expectLater(
        timeoutService.forecast(
          location: origin,
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 1),
        ),
        throwsA(
          isA<WeatherProviderException>().having(
            (error) => error.kind,
            'kind',
            WeatherProviderFailureKind.timeout,
          ),
        ),
      );
      pending.complete(http.Response('{}', 200));
      timeoutService.close();
    });
  });
}

String _validResponse(List<Map<String, Object?>> points) => jsonEncode({
  'cod': '200',
  'city': {
    'name': 'Samal',
    'country': 'PH',
    'coord': {'lat': 7.1, 'lon': 125.6},
    'timezone': 28800,
  },
  'list': points,
});

Map<String, Object?> _point(DateTime forecastAt) => {
  'dt': forecastAt.toUtc().millisecondsSinceEpoch ~/ 1000,
  'main': {'temp': 27.5, 'feels_like': 29.0, 'pressure': 1008, 'humidity': 82},
  'weather': [
    {'id': 500, 'main': 'Rain', 'description': 'light rain'},
  ],
  'wind': {'speed': 2.1},
  'clouds': {'all': 75},
  'rain': {'3h': 1.2},
};
