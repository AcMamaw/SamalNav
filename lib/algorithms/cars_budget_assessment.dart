import '../models/destination_record.dart';
import '../models/itinerary_draft.dart';

enum BudgetCostComponent {
  entrance,
  activity,
  transport,
  food,
  accommodation,
  packageBundle,
}

enum BudgetPricingUnit {
  perPerson,
  perAdult,
  perChild,
  perElder,
  perGroup,
  perVehicle,
  perRoom,
  perActivity,
  perItem,
  other,
}

enum BudgetPriceVerification { verified, unverified, unknown }

enum BudgetComponentDisposition { complete, notRequired, incomplete, unknown }

enum BudgetAssessmentStatus { withinBudget, overBudget, insufficientData }

/// A price fact with explicit currency, unit, provenance, verification and
/// freshness. Missing facts stay nullable so the assessor can explain gaps.
class BudgetCostItem {
  BudgetCostItem({
    required this.id,
    required this.component,
    required this.amount,
    required this.currency,
    required this.pricingUnit,
    required this.verification,
    required this.source,
    required this.retrievedAt,
    required this.freshUntil,
    this.quantity,
    this.coveredByPackageId,
    Set<BudgetCostComponent> includedComponents = const {},
  }) : includedComponents = Set.unmodifiable(includedComponents);

  /// Adapts today's destination fee model without upgrading its trust state.
  /// Current records contain no verified currency, pricing unit, price source,
  /// or freshness fields, so they cannot enter a reliable cost total.
  factory BudgetCostItem.fromDestinationEntranceFee(
    DestinationRecord destination,
  ) => BudgetCostItem(
    id: 'entrance:${destination.id}',
    component: BudgetCostComponent.entrance,
    amount: destination.entrancePrice.amount,
    currency: null,
    pricingUnit: null,
    verification: BudgetPriceVerification.unverified,
    source: null,
    retrievedAt: null,
    freshUntil: null,
  );

  final String id;
  final BudgetCostComponent component;
  final double? amount;
  final String? currency;
  final BudgetPricingUnit? pricingUnit;
  final BudgetPriceVerification verification;
  final String? source;
  final DateTime? retrievedAt;
  final DateTime? freshUntil;

  /// Required explicitly for per-vehicle, per-room, per-activity and per-item
  /// prices. The assessor never derives vehicle, room, or activity counts.
  final double? quantity;

  /// A line item may be skipped only when the referenced package explicitly
  /// lists it in [BudgetCostItem.includedComponents] by component.
  final String? coveredByPackageId;
  final Set<BudgetCostComponent> includedComponents;
}

class BudgetComponentCoverage {
  const BudgetComponentCoverage({
    required this.disposition,
    required this.verified,
    required this.source,
    required this.retrievedAt,
    required this.freshUntil,
  });

  final BudgetComponentDisposition disposition;
  final bool verified;
  final String? source;
  final DateTime? retrievedAt;
  final DateTime? freshUntil;

  bool isCurrentAt(DateTime now) =>
      verified &&
      source != null &&
      source!.trim().isNotEmpty &&
      retrievedAt != null &&
      !retrievedAt!.isAfter(now) &&
      freshUntil != null &&
      freshUntil!.isAfter(now);
}

class CarsBudgetAssessment {
  CarsBudgetAssessment({
    required this.status,
    required this.currency,
    required this.knownSubtotal,
    required this.totalCost,
    required this.effectiveBudgetMaximum,
    required this.groupSize,
    required this.adults,
    required this.children,
    required this.elders,
    required List<String> missingInformation,
    required Map<BudgetCostComponent, double> costBreakdown,
  }) : missingInformation = List.unmodifiable(missingInformation),
       costBreakdown = Map.unmodifiable(costBreakdown);

  final BudgetAssessmentStatus status;
  final String? currency;

  /// Sum of validated, independently chargeable items. It may be partial if
  /// another component is unavailable; it must not be compared to a budget.
  final double? knownSubtotal;

  /// Set only when every cost component and budget input is complete.
  final double? totalCost;
  final double? effectiveBudgetMaximum;
  final int? groupSize;
  final int? adults;
  final int? children;
  final int? elders;
  final List<String> missingInformation;
  final Map<BudgetCostComponent, double> costBreakdown;

  bool get isComplete => status != BudgetAssessmentStatus.insufficientData;
}

/// Calculates a cost total and compares it with the stated upper budget bound.
/// It is a raw budget assessment, not a CARS score or scoring formula.
class CarsBudgetAssessmentService {
  const CarsBudgetAssessmentService();

  static const _budgetedComponents = [
    BudgetCostComponent.entrance,
    BudgetCostComponent.activity,
    BudgetCostComponent.transport,
    BudgetCostComponent.food,
    BudgetCostComponent.accommodation,
  ];

  CarsBudgetAssessment assess({
    required TripConfiguration trip,
    required List<BudgetCostItem> costs,
    required Map<BudgetCostComponent, BudgetComponentCoverage> coverage,
    required DateTime now,
  }) {
    final reasons = <String>{};
    final currency = _normalizeCurrency(trip.currency);
    final budgetMaximum = trip.budgetMaximum;
    if (budgetMaximum == null || !budgetMaximum.isFinite || budgetMaximum < 0) {
      reasons.add('A valid maximum budget was not supplied.');
    }
    if (currency == null) {
      reasons.add('The budget currency is missing or blank.');
    }
    if (trip.budgetBasis == null) {
      reasons.add('The budget basis is unspecified.');
    }
    if (trip.budgetMinimum != null &&
        (!trip.budgetMinimum!.isFinite ||
            trip.budgetMinimum! < 0 ||
            (budgetMaximum != null && trip.budgetMinimum! > budgetMaximum))) {
      reasons.add('The supplied budget range is invalid.');
    }

    final group = _readGroup(trip, reasons);
    var effectiveBudgetMaximum = budgetMaximum;
    if (trip.budgetBasis == BudgetBasis.perPerson) {
      if (group == null) {
        reasons.add(
          'A complete adult, child, and elder group composition is required to convert the per-person budget.',
        );
        effectiveBudgetMaximum = null;
      } else if (budgetMaximum != null) {
        effectiveBudgetMaximum = budgetMaximum * group.total;
      }
    }

    final uniqueItems = <String, BudgetCostItem>{};
    for (final item in costs) {
      if (item.id.trim().isEmpty || uniqueItems.containsKey(item.id)) {
        reasons.add('Cost item identifiers must be present and unique.');
      } else {
        uniqueItems[item.id] = item;
      }
    }

    final coveredComponents = <BudgetCostComponent>{};
    final billableItems = <BudgetCostItem>[];
    for (final item in uniqueItems.values) {
      final packageId = item.coveredByPackageId;
      if (packageId != null) {
        final package = uniqueItems[packageId];
        if (package == null ||
            package.component != BudgetCostComponent.packageBundle ||
            !package.includedComponents.contains(item.component)) {
          reasons.add(
            '${item.component.name} item ${item.id} has no verified matching package inclusion.',
          );
        } else {
          coveredComponents.add(item.component);
        }
        continue;
      }
      billableItems.add(item);
      if (item.component != BudgetCostComponent.packageBundle) {
        coveredComponents.add(item.component);
      }
    }

    final costBreakdown = <BudgetCostComponent, double>{};
    final validatedAmounts = <double>[];
    for (final item in billableItems) {
      final amount = _validateAndExtend(item, group, now, reasons);
      if (amount == null) continue;
      final itemCurrency = _normalizeCurrency(item.currency);
      if (currency != null &&
          itemCurrency != null &&
          itemCurrency != currency) {
        reasons.add(
          'Cost item ${item.id} uses $itemCurrency while the budget uses $currency; no currency conversion is configured.',
        );
        continue;
      }
      if (itemCurrency == null) continue;
      validatedAmounts.add(amount);
      costBreakdown.update(
        item.component,
        (existing) => existing + amount,
        ifAbsent: () => amount,
      );
    }

    for (final component in _budgetedComponents) {
      final declared = coverage[component];
      if (declared == null) {
        reasons.add('Coverage for ${component.name} costs is unknown.');
        continue;
      }
      if (!declared.isCurrentAt(now)) {
        reasons.add(
          'Coverage for ${component.name} costs is unverified, expired, or missing source/freshness evidence.',
        );
        continue;
      }
      switch (declared.disposition) {
        case BudgetComponentDisposition.complete:
          if (!coveredComponents.contains(component)) {
            reasons.add(
              '${component.name} costs are marked complete but no cost or included package item was supplied.',
            );
          }
          break;
        case BudgetComponentDisposition.notRequired:
          if (coveredComponents.contains(component)) {
            reasons.add(
              '${component.name} costs are marked not required but a cost item is present.',
            );
          }
          break;
        case BudgetComponentDisposition.incomplete:
          reasons.add('Some ${component.name} costs are unavailable.');
          break;
        case BudgetComponentDisposition.unknown:
          reasons.add('Whether ${component.name} costs apply is unknown.');
          break;
      }
    }

    if (validatedAmounts.isEmpty && reasons.isEmpty) {
      reasons.add(
        'No verified cost amount was supplied; missing cost rows are not treated as zero.',
      );
    }
    final knownSubtotal = currency == null || validatedAmounts.isEmpty
        ? null
        : validatedAmounts.fold<double>(0, (sum, amount) => sum + amount);
    final double? totalCost;
    final BudgetAssessmentStatus status;
    if (reasons.isEmpty &&
        knownSubtotal != null &&
        effectiveBudgetMaximum != null) {
      totalCost = knownSubtotal;
      status = knownSubtotal <= effectiveBudgetMaximum
          ? BudgetAssessmentStatus.withinBudget
          : BudgetAssessmentStatus.overBudget;
    } else {
      totalCost = null;
      status = BudgetAssessmentStatus.insufficientData;
    }

    return CarsBudgetAssessment(
      status: status,
      currency: currency,
      knownSubtotal: knownSubtotal,
      totalCost: totalCost,
      effectiveBudgetMaximum: effectiveBudgetMaximum,
      groupSize: group?.total,
      adults: group?.adults,
      children: group?.children,
      elders: group?.elders,
      missingInformation: reasons.toList()..sort(),
      costBreakdown: costBreakdown,
    );
  }

  double? _validateAndExtend(
    BudgetCostItem item,
    _GroupComposition? group,
    DateTime now,
    Set<String> reasons,
  ) {
    final amount = item.amount;
    if (amount == null || !amount.isFinite || amount < 0) {
      reasons.add('Cost item ${item.id} has no valid amount.');
      return null;
    }
    if (item.verification != BudgetPriceVerification.verified) {
      reasons.add('Cost item ${item.id} is not verified.');
      return null;
    }
    if (item.source == null || item.source!.trim().isEmpty) {
      reasons.add('Cost item ${item.id} has no source.');
      return null;
    }
    if (item.retrievedAt == null || item.retrievedAt!.isAfter(now)) {
      reasons.add('Cost item ${item.id} has no valid retrieval timestamp.');
      return null;
    }
    if (item.freshUntil == null || !item.freshUntil!.isAfter(now)) {
      reasons.add('Cost item ${item.id} is expired or has no freshness limit.');
      return null;
    }
    if (_normalizeCurrency(item.currency) == null) {
      reasons.add('Cost item ${item.id} has no currency.');
      return null;
    }
    final unit = item.pricingUnit;
    if (unit == null || unit == BudgetPricingUnit.other) {
      reasons.add('Cost item ${item.id} has an ambiguous pricing unit.');
      return null;
    }

    final multiplier = switch (unit) {
      BudgetPricingUnit.perPerson => group?.total,
      BudgetPricingUnit.perAdult => group?.adults,
      BudgetPricingUnit.perChild => group?.children,
      BudgetPricingUnit.perElder => group?.elders,
      BudgetPricingUnit.perGroup => 1,
      BudgetPricingUnit.perVehicle ||
      BudgetPricingUnit.perRoom ||
      BudgetPricingUnit.perActivity ||
      BudgetPricingUnit.perItem => item.quantity,
      BudgetPricingUnit.other => null,
    };
    if (multiplier == null || !multiplier.isFinite || multiplier < 0) {
      reasons.add(
        unit == BudgetPricingUnit.perPerson ||
                unit == BudgetPricingUnit.perAdult ||
                unit == BudgetPricingUnit.perChild ||
                unit == BudgetPricingUnit.perElder
            ? 'A complete group composition is required for cost item ${item.id}.'
            : 'Cost item ${item.id} requires an explicit positive quantity for ${unit.name}.',
      );
      return null;
    }
    if ((unit == BudgetPricingUnit.perVehicle ||
            unit == BudgetPricingUnit.perRoom ||
            unit == BudgetPricingUnit.perActivity ||
            unit == BudgetPricingUnit.perItem) &&
        multiplier <= 0) {
      reasons.add(
        'Cost item ${item.id} requires an explicit positive quantity for ${unit.name}.',
      );
      return null;
    }
    return amount * multiplier;
  }

  _GroupComposition? _readGroup(TripConfiguration trip, Set<String> reasons) {
    final total = trip.totalGroupSize;
    final children = trip.childrenCount;
    final elders = trip.eldersCount;
    if (total == null && children == null && elders == null) return null;
    if (total == null || children == null || elders == null) {
      reasons.add(
        'Group size must include total people, children, and elders to derive adults safely.',
      );
      return null;
    }
    if (total <= 0 || children < 0 || elders < 0 || children + elders > total) {
      reasons.add('Group composition is invalid.');
      return null;
    }
    return _GroupComposition(
      total: total,
      children: children,
      elders: elders,
      adults: total - children - elders,
    );
  }

  String? _normalizeCurrency(String? currency) {
    final value = currency?.trim();
    return value == null || value.isEmpty ? null : value.toUpperCase();
  }
}

class _GroupComposition {
  const _GroupComposition({
    required this.total,
    required this.adults,
    required this.children,
    required this.elders,
  });

  final int total;
  final int adults;
  final int children;
  final int elders;
}
