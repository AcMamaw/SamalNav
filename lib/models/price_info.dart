/// Reliability state for an amount whose currency and pricing basis may be
/// unknown. This model deliberately has no verified/free state: the current
/// data contract does not provide evidence to establish either.
enum PriceDataStatus { unknown, recordedUnverified, invalidUnverified }

/// A source amount that is not yet suitable as a confirmed budget input.
///
/// [rawValue] preserves the value received from its caller or database. A
/// parsed [amount] is exposed only for finite, nonnegative numeric values.
class PriceInfo {
  final Object? rawValue;
  final double? amount;
  final PriceDataStatus status;

  const PriceInfo._({
    required this.rawValue,
    required this.amount,
    required this.status,
  });

  factory PriceInfo.fromRaw(Object? rawValue) {
    if (rawValue == null ||
        (rawValue is String && rawValue.trim().isEmpty)) {
      return PriceInfo._(
        rawValue: rawValue,
        amount: null,
        status: PriceDataStatus.unknown,
      );
    }

    final parsed = switch (rawValue) {
      num value => value.toDouble(),
      String value => double.tryParse(value.trim()),
      _ => null,
    };

    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return PriceInfo._(
        rawValue: rawValue,
        amount: null,
        status: PriceDataStatus.invalidUnverified,
      );
    }

    return PriceInfo._(
      rawValue: rawValue,
      amount: parsed,
      status: PriceDataStatus.recordedUnverified,
    );
  }

  bool get hasRecordedAmount =>
      status == PriceDataStatus.recordedUnverified;

  /// No amount is currently approved as a reliable CARS budget input.
  bool get isEligibleForBudgetScoring => false;

  String get displayLabel {
    switch (status) {
      case PriceDataStatus.unknown:
        return 'Price unavailable';
      case PriceDataStatus.invalidUnverified:
        return 'Price unavailable';
      case PriceDataStatus.recordedUnverified:
        return 'Unverified amount: ${_formatAmount(amount!)}';
    }
  }

  static String _formatAmount(double value) =>
      value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toString();
}
