import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/cars_budget_assessment.dart';
import 'package:samal_nav/models/destination_record.dart';
import 'package:samal_nav/models/itinerary_draft.dart';

void main() {
  const assessor = CarsBudgetAssessmentService();
  final now = DateTime.utc(2026, 6, 1, 12);

  group('CarsBudgetAssessmentService', () {
    test(
      'compares total-group budget with explicit per-person and vehicle costs',
      () {
        final result = assessor.assess(
          trip: _trip(
            maximum: 1000,
            basis: BudgetBasis.totalGroup,
            total: 4,
            children: 1,
            elders: 1,
          ),
          costs: [
            _cost(
              id: 'entry',
              component: BudgetCostComponent.entrance,
              amount: 100,
              unit: BudgetPricingUnit.perPerson,
            ),
            _cost(
              id: 'van',
              component: BudgetCostComponent.transport,
              amount: 300,
              unit: BudgetPricingUnit.perVehicle,
              quantity: 1,
            ),
          ],
          coverage: _coverage(now, {
            BudgetCostComponent.entrance,
            BudgetCostComponent.transport,
          }),
          now: now,
        );

        expect(result.status, BudgetAssessmentStatus.withinBudget);
        expect(result.groupSize, 4);
        expect(result.adults, 2);
        expect(result.children, 1);
        expect(result.elders, 1);
        expect(result.totalCost, 700);
        expect(result.effectiveBudgetMaximum, 1000);
      },
    );

    test('converts per-person budget using the complete group composition', () {
      final result = assessor.assess(
        trip: _trip(
          maximum: 200,
          basis: BudgetBasis.perPerson,
          total: 4,
          children: 1,
          elders: 1,
        ),
        costs: [
          _cost(
            id: 'adult',
            component: BudgetCostComponent.entrance,
            amount: 100,
            unit: BudgetPricingUnit.perAdult,
          ),
          _cost(
            id: 'child',
            component: BudgetCostComponent.entrance,
            amount: 50,
            unit: BudgetPricingUnit.perChild,
          ),
          _cost(
            id: 'elder',
            component: BudgetCostComponent.entrance,
            amount: 75,
            unit: BudgetPricingUnit.perElder,
          ),
        ],
        coverage: _coverage(now),
        now: now,
      );

      expect(result.status, BudgetAssessmentStatus.withinBudget);
      expect(result.totalCost, 325);
      expect(result.effectiveBudgetMaximum, 800);
    });

    test('per-person costs change with explicit group composition', () {
      CarsBudgetAssessment assessFor(int people) => assessor.assess(
        trip: _trip(
          maximum: 500,
          basis: BudgetBasis.totalGroup,
          total: people,
          children: 0,
          elders: 0,
        ),
        costs: [
          _cost(
            id: 'ticket',
            component: BudgetCostComponent.entrance,
            amount: 100,
            unit: BudgetPricingUnit.perPerson,
          ),
        ],
        coverage: _coverage(now),
        now: now,
      );

      expect(assessFor(2).totalCost, 200);
      expect(assessFor(4).totalCost, 400);
    });

    test('does not infer a budget basis or group composition', () {
      final unspecified = assessor.assess(
        trip: _trip(maximum: 300, basis: null),
        costs: [
          _cost(
            id: 'group',
            component: BudgetCostComponent.entrance,
            amount: 100,
            unit: BudgetPricingUnit.perGroup,
          ),
        ],
        coverage: _coverage(now),
        now: now,
      );
      expect(unspecified.status, BudgetAssessmentStatus.insufficientData);
      expect(unspecified.totalCost, isNull);
      expect(
        unspecified.missingInformation,
        contains('The budget basis is unspecified.'),
      );

      final perPersonNoGroup = assessor.assess(
        trip: _trip(maximum: 300, basis: BudgetBasis.perPerson),
        costs: [
          _cost(
            id: 'group',
            component: BudgetCostComponent.entrance,
            amount: 100,
            unit: BudgetPricingUnit.perGroup,
          ),
        ],
        coverage: _coverage(now),
        now: now,
      );
      expect(perPersonNoGroup.status, BudgetAssessmentStatus.insufficientData);
      expect(perPersonNoGroup.effectiveBudgetMaximum, isNull);
    });

    test(
      'missing or legacy unverified destination prices remain unavailable',
      () {
        final destination = DestinationRecord(
          id: 'dest-1',
          name: 'Beach',
          location: 'Samal',
          lat: 7,
          lng: 125,
          category: 'Beach',
          rating: null,
          status: 'active',
          isVerified: true,
          rawEntranceFee: 0,
          source: DestinationRecordSource.database,
        );
        final legacy = BudgetCostItem.fromDestinationEntranceFee(destination);
        final missing = BudgetCostItem(
          id: 'activity',
          component: BudgetCostComponent.activity,
          amount: null,
          currency: null,
          pricingUnit: null,
          verification: BudgetPriceVerification.unknown,
          source: null,
          retrievedAt: null,
          freshUntil: null,
        );

        final result = assessor.assess(
          trip: _trip(maximum: 500, basis: BudgetBasis.totalGroup),
          costs: [legacy, missing],
          coverage: _coverage(now, {
            BudgetCostComponent.entrance,
            BudgetCostComponent.activity,
          }),
          now: now,
        );

        expect(legacy.amount, 0);
        expect(legacy.verification, BudgetPriceVerification.unverified);
        expect(result.status, BudgetAssessmentStatus.insufficientData);
        expect(result.totalCost, isNull);
        expect(result.missingInformation, anyElement(contains('not verified')));
        expect(
          result.missingInformation,
          anyElement(contains('no valid amount')),
        );
      },
    );

    test('rejects ambiguous units, missing currency, and expired evidence', () {
      final costs = [
        _cost(
          id: 'ambiguous',
          component: BudgetCostComponent.entrance,
          amount: 10,
          unit: BudgetPricingUnit.other,
        ),
        _cost(
          id: 'no-currency',
          component: BudgetCostComponent.activity,
          amount: 10,
          unit: BudgetPricingUnit.perActivity,
          quantity: 1,
          currency: null,
        ),
        _cost(
          id: 'expired',
          component: BudgetCostComponent.food,
          amount: 10,
          unit: BudgetPricingUnit.perPerson,
          freshUntil: now,
        ),
      ];
      final result = assessor.assess(
        trip: _trip(
          maximum: 500,
          basis: BudgetBasis.totalGroup,
          total: 2,
          children: 0,
          elders: 0,
        ),
        costs: costs,
        coverage: _coverage(now, {
          BudgetCostComponent.entrance,
          BudgetCostComponent.activity,
          BudgetCostComponent.food,
        }),
        now: now,
      );

      expect(result.status, BudgetAssessmentStatus.insufficientData);
      expect(result.totalCost, isNull);
      expect(
        result.missingInformation,
        anyElement(contains('ambiguous pricing unit')),
      );
      expect(
        result.missingInformation,
        anyElement(contains('has no currency')),
      );
      expect(result.missingInformation, anyElement(contains('expired')));
    });

    test('does not combine mixed currencies', () {
      final result = assessor.assess(
        trip: _trip(maximum: 500, basis: BudgetBasis.totalGroup),
        costs: [
          _cost(
            id: 'php',
            component: BudgetCostComponent.entrance,
            amount: 100,
            unit: BudgetPricingUnit.perGroup,
          ),
          _cost(
            id: 'usd',
            component: BudgetCostComponent.activity,
            amount: 5,
            unit: BudgetPricingUnit.perGroup,
            currency: 'USD',
          ),
        ],
        coverage: _coverage(now, {
          BudgetCostComponent.entrance,
          BudgetCostComponent.activity,
        }),
        now: now,
      );

      expect(result.status, BudgetAssessmentStatus.insufficientData);
      expect(result.totalCost, isNull);
      expect(
        result.missingInformation,
        anyElement(contains('no currency conversion')),
      );
    });

    test(
      'counts a package once and does not double-count included transport',
      () {
        final result = assessor.assess(
          trip: _trip(maximum: 900, basis: BudgetBasis.totalGroup),
          costs: [
            _cost(
              id: 'package',
              component: BudgetCostComponent.packageBundle,
              amount: 700,
              unit: BudgetPricingUnit.perGroup,
              included: {BudgetCostComponent.transport},
            ),
            _cost(
              id: 'transport',
              component: BudgetCostComponent.transport,
              amount: 300,
              unit: BudgetPricingUnit.perVehicle,
              quantity: 1,
              coveredByPackageId: 'package',
            ),
            _cost(
              id: 'entry',
              component: BudgetCostComponent.entrance,
              amount: 100,
              unit: BudgetPricingUnit.perGroup,
            ),
          ],
          coverage: _coverage(now, {
            BudgetCostComponent.entrance,
            BudgetCostComponent.transport,
          }),
          now: now,
        );

        expect(result.status, BudgetAssessmentStatus.withinBudget);
        expect(result.totalCost, 800);
        expect(result.costBreakdown[BudgetCostComponent.packageBundle], 700);
        expect(
          result.costBreakdown.containsKey(BudgetCostComponent.transport),
          isFalse,
        );
      },
    );

    test('incomplete component coverage prevents a complete assessment', () {
      final coverage = _coverage(now)..remove(BudgetCostComponent.food);
      final result = assessor.assess(
        trip: _trip(maximum: 500, basis: BudgetBasis.totalGroup),
        costs: [
          _cost(
            id: 'entry',
            component: BudgetCostComponent.entrance,
            amount: 100,
            unit: BudgetPricingUnit.perGroup,
          ),
        ],
        coverage: coverage,
        now: now,
      );

      expect(result.status, BudgetAssessmentStatus.insufficientData);
      expect(result.totalCost, isNull);
      expect(
        result.missingInformation,
        contains('Coverage for food costs is unknown.'),
      );
    });

    test('does not treat absent cost rows as an explicit zero total', () {
      final result = assessor.assess(
        trip: _trip(maximum: 500, basis: BudgetBasis.totalGroup),
        costs: const [],
        coverage: _coverage(now, {}),
        now: now,
      );

      expect(result.status, BudgetAssessmentStatus.insufficientData);
      expect(result.totalCost, isNull);
      expect(
        result.missingInformation,
        contains(
          'No verified cost amount was supplied; missing cost rows are not treated as zero.',
        ),
      );
    });
  });
}

TripConfiguration _trip({
  required double maximum,
  required BudgetBasis? basis,
  int? total,
  int? children,
  int? elders,
}) => TripConfiguration(
  durationDays: 1,
  availableHoursPerDay: 8,
  budgetMaximum: maximum,
  budgetBasis: basis,
  currency: 'PHP',
  totalGroupSize: total,
  childrenCount: children,
  eldersCount: elders,
);

BudgetCostItem _cost({
  required String id,
  required BudgetCostComponent component,
  required double amount,
  required BudgetPricingUnit unit,
  String? currency = 'PHP',
  double? quantity,
  DateTime? freshUntil,
  String? coveredByPackageId,
  Set<BudgetCostComponent> included = const {},
}) => BudgetCostItem(
  id: id,
  component: component,
  amount: amount,
  currency: currency,
  pricingUnit: unit,
  verification: BudgetPriceVerification.verified,
  source: 'owner-verified test source',
  retrievedAt: DateTime.utc(2026, 6, 1, 10),
  freshUntil: freshUntil ?? DateTime.utc(2026, 6, 2),
  quantity: quantity,
  coveredByPackageId: coveredByPackageId,
  includedComponents: included,
);

Map<BudgetCostComponent, BudgetComponentCoverage> _coverage(
  DateTime now, [
  Set<BudgetCostComponent> complete = const {BudgetCostComponent.entrance},
]) => {
  for (final component in [
    BudgetCostComponent.entrance,
    BudgetCostComponent.activity,
    BudgetCostComponent.transport,
    BudgetCostComponent.food,
    BudgetCostComponent.accommodation,
  ])
    component: BudgetComponentCoverage(
      disposition: complete.contains(component)
          ? BudgetComponentDisposition.complete
          : BudgetComponentDisposition.notRequired,
      verified: true,
      source: 'owner-verified test source',
      retrievedAt: now.subtract(const Duration(hours: 1)),
      freshUntil: now.add(const Duration(hours: 1)),
    ),
};
