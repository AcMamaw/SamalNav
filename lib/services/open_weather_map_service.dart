import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/destination_record.dart';
import '../models/itinerary_draft.dart';

/// Units requested from OpenWeatherMap. Units are retained with every result;
/// values are never silently converted after retrieval.
enum WeatherUnits {
  standard('standard', 'K', 'm/s'),
  metric('metric', '°C', 'm/s'),
  imperial('imperial', '°F', 'mph');

  const WeatherUnits(this.apiValue, this.temperatureLabel, this.windLabel);

  final String apiValue;
  final String temperatureLabel;
  final String windLabel;
}

enum WeatherForecastCoverage { available, partial, stale, unavailable }

enum WeatherProviderFailureKind {
  missingCredentials,
  invalidCredentials,
  rateLimited,
  invalidRequest,
  timeout,
  network,
  providerUnavailable,
  malformedResponse,
  missingLocation,
  missingTripDates,
}

/// Safe-to-display failure. It intentionally never includes the request URI,
/// response body, or API credential.
class WeatherProviderException implements Exception {
  const WeatherProviderException(this.kind, this.message);

  final WeatherProviderFailureKind kind;
  final String message;

  @override
  String toString() => message;
}

class WeatherLocation {
  const WeatherLocation({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  final double latitude;
  final double longitude;
  final String? label;

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude.isFinite &&
      longitude >= -180 &&
      longitude <= 180;

  factory WeatherLocation.fromTripOrigin(TripOrigin origin) => WeatherLocation(
    latitude: origin.latitude,
    longitude: origin.longitude,
    label: origin.label,
  );

  factory WeatherLocation.fromDestination(DestinationRecord destination) =>
      WeatherLocation(
        latitude: destination.lat,
        longitude: destination.lng,
        label: destination.name,
      );
}

class WeatherForecastPoint {
  const WeatherForecastPoint({
    required this.forecastAtUtc,
    required this.temperature,
    required this.conditionId,
    required this.conditionMain,
    required this.description,
    this.feelsLike,
    this.pressureHpa,
    this.humidityPercent,
    this.windSpeed,
    this.cloudinessPercent,
    this.rainLastThreeHoursMm,
    this.snowLastThreeHoursMm,
  });

  final DateTime forecastAtUtc;
  final double temperature;
  final int conditionId;
  final String conditionMain;
  final String description;
  final double? feelsLike;
  final double? pressureHpa;
  final double? humidityPercent;
  final double? windSpeed;
  final double? cloudinessPercent;
  final double? rainLastThreeHoursMm;
  final double? snowLastThreeHoursMm;

  bool isExpiredAt(DateTime now) => !forecastAtUtc.isAfter(now.toUtc());

  Map<String, Object?> toJson() => {
    'forecastAtUtc': forecastAtUtc.toIso8601String(),
    'temperature': temperature,
    'conditionId': conditionId,
    'conditionMain': conditionMain,
    'description': description,
    if (feelsLike != null) 'feelsLike': feelsLike,
    if (pressureHpa != null) 'pressureHpa': pressureHpa,
    if (humidityPercent != null) 'humidityPercent': humidityPercent,
    if (windSpeed != null) 'windSpeed': windSpeed,
    if (cloudinessPercent != null) 'cloudinessPercent': cloudinessPercent,
    if (rainLastThreeHoursMm != null)
      'rainLastThreeHoursMm': rainLastThreeHoursMm,
    if (snowLastThreeHoursMm != null)
      'snowLastThreeHoursMm': snowLastThreeHoursMm,
  };
}

class WeatherForecastResult {
  WeatherForecastResult({
    required this.requestedLocation,
    required this.providerLatitude,
    required this.providerLongitude,
    required this.providerLocationName,
    required this.providerCountryCode,
    required this.providerTimezoneOffsetSeconds,
    required this.requestedStartDate,
    required this.requestedEndDate,
    required this.units,
    required this.retrievedAt,
    required List<WeatherForecastPoint> points,
    required this.coverage,
    required List<DateTime> uncoveredDates,
  }) : points = List.unmodifiable(points),
       uncoveredDates = List.unmodifiable(uncoveredDates);

  final WeatherLocation requestedLocation;
  final double providerLatitude;
  final double providerLongitude;
  final String? providerLocationName;
  final String? providerCountryCode;

  /// OpenWeatherMap reports this as a seconds offset from UTC.
  final int providerTimezoneOffsetSeconds;
  final DateTime requestedStartDate;
  final DateTime requestedEndDate;
  final WeatherUnits units;
  final DateTime retrievedAt;
  final List<WeatherForecastPoint> points;
  final WeatherForecastCoverage coverage;
  final List<DateTime> uncoveredDates;

  bool get isAvailable => coverage == WeatherForecastCoverage.available;
  bool get isStale => coverage == WeatherForecastCoverage.stale;

  /// Raw, provenance-bearing data compatible with [CarsRawContext.weatherObservation].
  /// It contains no suitability score and makes incomplete coverage explicit.
  Map<String, Object?> toCarsWeatherObservation() => {
    'provider': 'OpenWeatherMap 5 day / 3 hour forecast',
    'requestedLocation': {
      'latitude': requestedLocation.latitude,
      'longitude': requestedLocation.longitude,
      if (requestedLocation.label != null) 'label': requestedLocation.label,
    },
    'providerLocation': {
      'latitude': providerLatitude,
      'longitude': providerLongitude,
      if (providerLocationName != null) 'name': providerLocationName,
      if (providerCountryCode != null) 'countryCode': providerCountryCode,
      'timezoneOffsetSeconds': providerTimezoneOffsetSeconds,
    },
    'requestedStartDate': _dateKey(requestedStartDate),
    'requestedEndDate': _dateKey(requestedEndDate),
    'units': units.apiValue,
    'temperatureUnit': units.temperatureLabel,
    'windSpeedUnit': units.windLabel,
    'precipitationUnit': 'mm per 3 hours',
    'retrievedAt': retrievedAt.toUtc().toIso8601String(),
    'coverage': coverage.name,
    'uncoveredDates': uncoveredDates.map(_dateKey).toList(growable: false),
    'forecasts': points.map((point) => point.toJson()).toList(growable: false),
  };
}

/// Injectable client for OpenWeatherMap's documented 5 day / 3 hour forecast.
///
/// Supply credentials from a trusted runtime boundary; never embed an API key
/// in Flutter source or a distributed client build. This service is deliberately
/// not wired into manual planning and does not calculate CARS scores.
class OpenWeatherMapService {
  OpenWeatherMapService({
    required String? apiKey,
    http.Client? client,
    DateTime Function()? clock,
    this.units = WeatherUnits.metric,
    this.timeout = const Duration(seconds: 12),
  }) : _apiKey = apiKey?.trim(),
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _clock = clock ?? DateTime.now;

  static final Uri _forecastEndpoint = Uri.https(
    'api.openweathermap.org',
    '/data/2.5/forecast',
  );

  final String? _apiKey;
  final http.Client _client;
  final bool _ownsClient;
  final DateTime Function() _clock;
  final WeatherUnits units;
  final Duration timeout;

  /// Uses an explicit selected [location], or the tourist-selected trip origin.
  /// It never requests device location. A destination can be supplied through
  /// [location] when destination-local weather is required.
  Future<WeatherForecastResult> forecastForTrip(
    TripConfiguration trip, {
    WeatherLocation? location,
  }) async {
    final selectedLocation =
        location ??
        (trip.origin == null
            ? null
            : WeatherLocation.fromTripOrigin(trip.origin!));
    if (selectedLocation == null) {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.missingLocation,
        'Weather is unavailable because no trip origin or selected destination coordinates were provided.',
      );
    }
    final start = trip.startDate;
    if (start == null || trip.durationDays < 1) {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.missingTripDates,
        'Weather forecast dates are unavailable because the trip dates are incomplete.',
      );
    }
    final startDate = DateTime.utc(start.year, start.month, start.day);
    final endDate = startDate.add(Duration(days: trip.durationDays - 1));
    return forecast(
      location: selectedLocation,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Forecast dates are inclusive calendar dates in the provider location's
  /// reported fixed UTC offset. OpenWeatherMap's documented 5-day product
  /// returns 3-hour steps; dates outside returned coverage remain uncovered.
  Future<WeatherForecastResult> forecast({
    required WeatherLocation location,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.missingCredentials,
        'Weather is unavailable because an OpenWeatherMap credential was not provided.',
      );
    }
    if (!location.hasValidCoordinates) {
      throw ArgumentError.value(location, 'location', 'Invalid coordinates.');
    }
    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final end = DateTime.utc(endDate.year, endDate.month, endDate.day);
    if (end.isBefore(start)) {
      throw ArgumentError('Forecast end date must not precede start date.');
    }

    final uri = _forecastEndpoint.replace(
      queryParameters: {
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'appid': key,
        'units': units.apiValue,
      },
    );

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.timeout,
        'The weather provider request timed out.',
      );
    } on http.ClientException {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.network,
        'The weather provider could not be reached.',
      );
    } on Exception {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.network,
        'The weather provider request failed.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.invalidCredentials,
        'The weather provider rejected its configured credential or access.',
      );
    }
    if (response.statusCode == 429) {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.rateLimited,
        'The weather provider rate limit was reached.',
      );
    }
    if (response.statusCode >= 500) {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.providerUnavailable,
        'The weather provider is temporarily unavailable.',
      );
    }
    if (response.statusCode != 200) {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.invalidRequest,
        'The weather provider did not accept the forecast request.',
      );
    }

    final now = _clock().toUtc();
    try {
      return _parseResponse(
        response.body,
        location: location,
        startDate: start,
        endDate: end,
        retrievedAt: now,
      );
    } on FormatException {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.malformedResponse,
        'The weather provider returned incomplete or malformed forecast data.',
      );
    } on TypeError {
      throw const WeatherProviderException(
        WeatherProviderFailureKind.malformedResponse,
        'The weather provider returned incomplete or malformed forecast data.',
      );
    }
  }

  WeatherForecastResult _parseResponse(
    String body, {
    required WeatherLocation location,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime retrievedAt,
  }) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object.');
    }
    if ('${decoded['cod']}' != '200') {
      throw const FormatException('Unexpected provider response code.');
    }
    final city = decoded['city'];
    final cityMap = _requiredMap(city, 'city');
    final coord = _requiredMap(cityMap['coord'], 'city.coord');
    final providerLat = _requiredFiniteNumber(coord['lat'], 'city.coord.lat');
    final providerLon = _requiredFiniteNumber(coord['lon'], 'city.coord.lon');
    if (providerLat < -90 ||
        providerLat > 90 ||
        providerLon < -180 ||
        providerLon > 180) {
      throw const FormatException('Provider location out of bounds.');
    }
    final timezoneOffset = _requiredInteger(
      cityMap['timezone'],
      'city.timezone',
    );
    final rawList = decoded['list'];
    if (rawList is! List) {
      throw const FormatException('Expected forecast list.');
    }

    final parsed = rawList.map(_parsePoint).toList(growable: false)
      ..sort((a, b) => a.forecastAtUtc.compareTo(b.forecastAtUtc));
    final localStart = startDate;
    final localEndExclusive = endDate.add(const Duration(days: 1));
    final requestedPoints = parsed
        .where((point) {
          final providerLocal = point.forecastAtUtc.add(
            Duration(seconds: timezoneOffset),
          );
          final localDate = DateTime.utc(
            providerLocal.year,
            providerLocal.month,
            providerLocal.day,
          );
          return !localDate.isBefore(localStart) &&
              localDate.isBefore(localEndExclusive);
        })
        .toList(growable: false);

    final requestedDates = <DateTime>[
      for (
        var date = startDate;
        !date.isAfter(endDate);
        date = date.add(const Duration(days: 1))
      )
        date,
    ];
    final futureCoveredDates = <DateTime>{};
    for (final point in requestedPoints) {
      if (point.forecastAtUtc.isBefore(retrievedAt)) continue;
      final providerLocal = point.forecastAtUtc.add(
        Duration(seconds: timezoneOffset),
      );
      futureCoveredDates.add(
        DateTime.utc(
          providerLocal.year,
          providerLocal.month,
          providerLocal.day,
        ),
      );
    }
    final uncovered = requestedDates
        .where((date) => !futureCoveredDates.contains(date))
        .toList(growable: false);
    final coverage = requestedPoints.isEmpty
        ? WeatherForecastCoverage.unavailable
        : futureCoveredDates.isEmpty
        ? WeatherForecastCoverage.stale
        : uncovered.isEmpty
        ? WeatherForecastCoverage.available
        : WeatherForecastCoverage.partial;

    return WeatherForecastResult(
      requestedLocation: location,
      providerLatitude: providerLat,
      providerLongitude: providerLon,
      providerLocationName: _optionalString(cityMap['name'], 'city.name'),
      providerCountryCode: _optionalString(cityMap['country'], 'city.country'),
      providerTimezoneOffsetSeconds: timezoneOffset,
      requestedStartDate: startDate,
      requestedEndDate: endDate,
      units: units,
      retrievedAt: retrievedAt,
      points: requestedPoints,
      coverage: coverage,
      uncoveredDates: uncovered,
    );
  }

  WeatherForecastPoint _parsePoint(Object? raw) {
    final point = _requiredMap(raw, 'forecast item');
    final seconds = _requiredInteger(point['dt'], 'forecast.dt');
    if (seconds <= 0) throw const FormatException('Invalid forecast time.');
    final main = _requiredMap(point['main'], 'forecast.main');
    final weather = point['weather'];
    if (weather is! List || weather.isEmpty) {
      throw const FormatException('Missing forecast condition.');
    }
    final condition = _requiredMap(weather.first, 'forecast.weather[0]');
    final conditionId = _requiredInteger(condition['id'], 'weather.id');
    final conditionMain = _requiredString(condition['main'], 'weather.main');
    final description = _requiredString(
      condition['description'],
      'weather.description',
    );
    final wind = point['wind'] == null
        ? null
        : _requiredMap(point['wind'], 'forecast.wind');
    final clouds = point['clouds'] == null
        ? null
        : _requiredMap(point['clouds'], 'forecast.clouds');

    return WeatherForecastPoint(
      forecastAtUtc: DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      ),
      temperature: _requiredFiniteNumber(main['temp'], 'main.temp'),
      conditionId: conditionId,
      conditionMain: conditionMain,
      description: description,
      feelsLike: _optionalFiniteNumber(main['feels_like'], 'main.feels_like'),
      pressureHpa: _optionalFiniteNumber(main['pressure'], 'main.pressure'),
      humidityPercent: _optionalFiniteNumber(main['humidity'], 'main.humidity'),
      windSpeed: wind == null
          ? null
          : _optionalFiniteNumber(wind['speed'], 'wind.speed'),
      cloudinessPercent: clouds == null
          ? null
          : _optionalFiniteNumber(clouds['all'], 'clouds.all'),
      rainLastThreeHoursMm: _optionalThreeHourVolume(point['rain'], 'rain'),
      snowLastThreeHoursMm: _optionalThreeHourVolume(point['snow'], 'snow'),
    );
  }

  double? _optionalThreeHourVolume(Object? raw, String field) {
    if (raw == null) return null;
    final map = _requiredMap(raw, field);
    return _optionalFiniteNumber(map['3h'], '$field.3h');
  }

  static Map<String, dynamic> _requiredMap(Object? value, String field) {
    if (value is Map<String, dynamic>) return value;
    throw FormatException('Invalid $field.');
  }

  static String _requiredString(Object? value, String field) {
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Invalid $field.');
  }

  static String? _optionalString(Object? value, String field) {
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Invalid $field.');
  }

  static int _requiredInteger(Object? value, String field) {
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw FormatException('Invalid $field.');
  }

  static double _requiredFiniteNumber(Object? value, String field) {
    final parsed = _optionalFiniteNumber(value, field);
    if (parsed == null) throw FormatException('Missing $field.');
    return parsed;
  }

  static double? _optionalFiniteNumber(Object? value, String field) {
    if (value == null) return null;
    if (value is num && value.isFinite) return value.toDouble();
    throw FormatException('Invalid $field.');
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
