import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/price_info.dart';
import 'package:samal_nav/models/cars_models.dart';

void main() {
  group('PriceInfo.fromRaw', () {
    test('missing and null values remain unknown', () {
      expect(PriceInfo.fromRaw(null).status, PriceDataStatus.unknown);
      expect(PriceInfo.fromRaw(null).amount, isNull);
    });

    test('zero is recorded but not interpreted as free', () {
      final price = PriceInfo.fromRaw(0);

      expect(price.status, PriceDataStatus.recordedUnverified);
      expect(price.amount, 0);
      expect(price.displayLabel, 'Unverified amount: 0');
      expect(price.displayLabel, isNot(contains('Free')));
      expect(price.isEligibleForBudgetScoring, isFalse);
    });

    test('positive values remain unverified and preserve the raw value', () {
      final price = PriceInfo.fromRaw('125.50');

      expect(price.rawValue, '125.50');
      expect(price.amount, 125.5);
      expect(price.status, PriceDataStatus.recordedUnverified);
      expect(price.displayLabel, 'Unverified amount: 125.5');
      expect(
        price.displayLabel,
        isNot(contains(String.fromCharCode(0x20B1))),
      );
      expect(price.isEligibleForBudgetScoring, isFalse);
    });

    test('invalid values are retained but cannot become amounts', () {
      for (final value in ['not-a-price', -1, double.nan, double.infinity]) {
        final price = PriceInfo.fromRaw(value);

        expect(price.rawValue, value);
        expect(price.amount, isNull);
        expect(price.status, PriceDataStatus.invalidUnverified);
        expect(price.displayLabel, 'Price unavailable');
        expect(price.isEligibleForBudgetScoring, isFalse);
      }
    });

    test('unverified state cannot be upgraded by parsing positive values', () {
      final price = PriceInfo.fromRaw(999);

      expect(
        PriceDataStatus.values,
        [
          PriceDataStatus.unknown,
          PriceDataStatus.recordedUnverified,
          PriceDataStatus.invalidUnverified,
        ],
      );
      expect(price.isEligibleForBudgetScoring, isFalse);
    });
  });

  group('DestinationRecord price parsing', () {
    DestinationRecord parse(Object? amount) => DestinationRecord.fromJson({
      'id': 'destination-1',
      'name': 'Test destination',
      'lat': 7.0,
      'lng': 125.0,
      'entrance_fee': amount,
    });

    test('missing and null fees are unavailable, not zero', () {
      final missing = DestinationRecord.fromJson({
        'id': 'destination-1',
        'name': 'Test destination',
        'lat': 7.0,
        'lng': 125.0,
      });
      final nullFee = parse(null);

      expect(missing.entrancePrice.status, PriceDataStatus.unknown);
      expect(missing.entrancePrice.amount, isNull);
      expect(missing.formattedPrice, 'Price unavailable');
      expect(nullFee.entrancePrice.status, PriceDataStatus.unknown);
      expect(nullFee.formattedPrice, 'Price unavailable');
    });

    test('zero and positive database fees are retained as unverified', () {
      final zero = parse(0);
      final positive = parse(150);

      expect(zero.rawEntranceFee, 0);
      expect(zero.entrancePrice.amount, 0);
      expect(zero.formattedPrice, 'Unverified amount: 0');
      expect(positive.rawEntranceFee, 150);
      expect(positive.entrancePrice.amount, 150);
      expect(positive.formattedPrice, 'Unverified amount: 150');
    });

    test('malformed database fee is preserved and shown unavailable', () {
      final invalid = parse('unknown');

      expect(invalid.rawEntranceFee, 'unknown');
      expect(invalid.entrancePrice.status, PriceDataStatus.invalidUnverified);
      expect(invalid.entrancePrice.amount, isNull);
      expect(invalid.formattedPrice, 'Price unavailable');
    });
  });

  test('CARS raw destination costs retain unverified price typing', () {
    final context = CarsRawContext(
      estimatedDestinationCost: PriceInfo.fromRaw(0),
    );

    expect(context.estimatedDestinationCost!.amount, 0);
    expect(
      context.estimatedDestinationCost!.isEligibleForBudgetScoring,
      isFalse,
    );
  });
}
