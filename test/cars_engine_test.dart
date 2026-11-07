import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/algorithms/cars_engine.dart';
import 'package:samal_nav/models/cars_models.dart';

// Synthetic test fixtures only. These are not SAMAL NAV destination records
// and are not survey-derived recommendation weights.
const testWeights = <CarsCriterion, double>{
  CarsCriterion.interestActivityMatch: 0.25,
  CarsCriterion.publicDestinationRating: 0.20,
  CarsCriterion.weatherSuitability: 0.15,
  CarsCriterion.budgetCompatibility: 0.15,
  CarsCriterion.travelDistanceSuitability: 0.15,
  CarsCriterion.availableTravelTimeCompatibility: 0.10,
};

CarsEligibilityEvaluator testEligibility() => CarsEligibilityEvaluator(
  CarsEligibilityPolicy(
    approvedStatuses: {'approved'},
    accreditedStatuses: {'accredited'},
  ),
);

CarsRecommendationEngine testEngine({Map<CarsCriterion, double>? weights}) =>
    CarsRecommendationEngine(
      weights: weights ?? testWeights,
      eligibilityEvaluator: testEligibility(),
    );

CarsCandidate testCandidate({
  String id = 'synthetic-1',
  String name = 'Synthetic destination',
  bool exists = true,
  String? approval = 'approved',
  String? accreditation = 'accredited',
  bool accreditationRequired = true,
  Set<String> supported = const {'step_free'},
  Set<String> required = const {'step_free'},
  Map<CarsCriterion, double?>? scores,
}) => CarsCandidate(
  destinationId: id,
  destinationName: name,
  existsInDataset: exists,
  approvalStatus: approval,
  accreditationStatus: accreditation,
  accreditationRequired: accreditationRequired,
  supportedSuitabilityCodes: supported,
  requiredSuitabilityCodes: required,
  criterionScores:
      scores ?? {for (final criterion in CarsCriterion.values) criterion: 80.0},
);

void main() {
  group('CarsRecommendationEngine', () {
    test('calculates the weighted recommendation score and contributions', () {
      final scores = {
        for (final criterion in CarsCriterion.values) criterion: 80.0,
      };
      final result = testEngine().rank([testCandidate(scores: scores)]);
      final item = result.ranked.single;

      expect(item.recommendationScore, closeTo(80, 1e-10));
      expect(item.criterionScores, scores);
      for (final criterion in CarsCriterion.values) {
        expect(
          item.weightedContributions![criterion],
          closeTo(testWeights[criterion]! * 80, 1e-10),
        );
      }
      expect(item.eligibility.isEligible, isTrue);
      expect(item.explanation, contains('80.00 / 100'));
    });

    test('sorts candidates by descending recommendation score', () {
      final lower = testCandidate(
        id: 'a',
        scores: {for (final criterion in CarsCriterion.values) criterion: 20},
      );
      final higher = testCandidate(
        id: 'b',
        scores: {for (final criterion in CarsCriterion.values) criterion: 90},
      );

      final result = testEngine().rank([lower, higher]);
      expect(result.ranked.map((item) => item.destinationId), ['b', 'a']);
    });

    test('breaks equal scores deterministically by destination ID', () {
      final candidates = [
        testCandidate(id: 'z'),
        testCandidate(id: 'a'),
        testCandidate(id: 'm'),
      ];

      expect(
        testEngine().rank(candidates).ranked.map((item) => item.destinationId),
        ['a', 'm', 'z'],
      );
      expect(
        testEngine()
            .rank(candidates.reversed)
            .ranked
            .map((item) => item.destinationId),
        ['a', 'm', 'z'],
      );
    });

    test('rejects weights whose sum is not one', () {
      expect(
        () => testEngine(
          weights: {...testWeights, CarsCriterion.weatherSuitability: 0.5},
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative and non-finite weights', () {
      expect(
        () => testEngine(
          weights: {...testWeights, CarsCriterion.weatherSuitability: -0.1},
        ),
        throwsArgumentError,
      );
      expect(
        () => testEngine(
          weights: {
            ...testWeights,
            CarsCriterion.weatherSuitability: double.nan,
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => testEngine(
          weights: {
            ...testWeights,
            CarsCriterion.weatherSuitability: double.infinity,
          },
        ),
        throwsArgumentError,
      );
    });

    test('rejects score below zero, above 100, or non-finite', () {
      for (final invalid in [-0.01, 100.01, double.nan, double.infinity]) {
        final scores = {
          for (final criterion in CarsCriterion.values) criterion: 50.0,
          CarsCriterion.weatherSuitability: invalid,
        };
        expect(
          () => testEngine().rank([testCandidate(scores: scores)]),
          throwsArgumentError,
        );
      }
    });

    test(
      'reports missing criterion scores without assigning zero or redistributing weights',
      () {
        final scores = {
          for (final criterion in CarsCriterion.values) criterion: 75.0,
        }..remove(CarsCriterion.weatherSuitability);
        final result = testEngine().rank([testCandidate(scores: scores)]);

        expect(result.ranked, isEmpty);
        expect(
          result.excluded.single.outcome,
          CarsCandidateOutcome.insufficientData,
        );
        expect(result.excluded.single.recommendationScore, isNull);
        expect(result.excluded.single.criterionScores, isNull);
        expect(result.excluded.single.missingCriteria, ['weatherSuitability']);
      },
    );

    test(
      'rejects an invalid supplied score even when another score is missing',
      () {
        final scores = {
          for (final criterion in CarsCriterion.values) criterion: 75.0,
        }..remove(CarsCriterion.weatherSuitability);
        scores[CarsCriterion.budgetCompatibility] = double.nan;

        expect(
          () => testEngine().rank([testCandidate(scores: scores)]),
          throwsArgumentError,
        );
      },
    );

    test('excludes candidates that fail eligibility before ranking', () {
      final result = testEngine().rank([
        testCandidate(id: 'not-approved', approval: 'pending'),
        testCandidate(id: 'not-accredited', accreditation: 'expired'),
        testCandidate(id: 'missing-dataset', exists: false),
        testCandidate(id: 'eligible'),
      ]);

      expect(result.ranked.map((item) => item.destinationId), ['eligible']);
      expect(result.excluded, hasLength(3));
      expect(
        result.excluded.every(
          (item) => item.outcome == CarsCandidateOutcome.ineligible,
        ),
        isTrue,
      );
    });

    test('eligibility is separate from all six weighted criteria', () {
      final lowScore = testCandidate(
        id: 'low-score',
        scores: {for (final criterion in CarsCriterion.values) criterion: 10},
      );
      final highScore = testCandidate(
        id: 'high-score',
        scores: {for (final criterion in CarsCriterion.values) criterion: 90},
      );

      final result = testEngine().rank([lowScore, highScore]);
      expect(result.ranked, hasLength(2));
      expect(result.ranked.first.destinationId, 'high-score');
      expect(
        result.ranked.every((item) => item.criterionScores!.length == 6),
        isTrue,
      );
      expect(
        result.ranked.every((item) => item.weightedContributions!.length == 6),
        isTrue,
      );
    });

    test('does not mutate supplied weights', () {
      final supplied = Map<CarsCriterion, double>.from(testWeights);
      final before = Map<CarsCriterion, double>.from(supplied);
      final engine = testEngine(weights: supplied);

      expect(supplied, before);
      expect(engine.weights, before);
      expect(
        () => engine.weights[CarsCriterion.weatherSuitability] = 0.9,
        throwsUnsupportedError,
      );
      expect(supplied, before);
    });

    test('uses configurable approval and accreditation states', () {
      final evaluator = CarsEligibilityEvaluator(
        CarsEligibilityPolicy(
          approvedStatuses: {'published'},
          accreditedStatuses: {'verified'},
        ),
      );
      final candidate = testCandidate(
        approval: 'PUBLISHED',
        accreditation: 'VERIFIED',
      );

      expect(evaluator.evaluate(candidate).isEligible, isTrue);
    });

    test(
      'allows no accreditation requirement when policy says it is inapplicable',
      () {
        final candidate = testCandidate(
          accreditation: null,
          accreditationRequired: false,
        );
        expect(testEligibility().evaluate(candidate).isEligible, isTrue);
      },
    );

    test('checks suitability using only declared and recorded codes', () {
      final eligible = testCandidate(
        supported: {'step_free', 'family_area'},
        required: {'step_free'},
      );
      final ineligible = testCandidate(
        id: 'unsuitable',
        supported: {'step_free'},
        required: {'step_free', 'family_area'},
      );

      expect(testEligibility().evaluate(eligible).isEligible, isTrue);
      final outcome = testEligibility().evaluate(ineligible);
      expect(outcome.isEligible, isFalse);
      expect(outcome.reasons.single, contains('family_area'));
    });

    test('ranks identical input deterministically across runs', () {
      final candidates = [testCandidate(id: 'b'), testCandidate(id: 'a')];
      final engine = testEngine();

      final first = engine.rank(candidates);
      final second = engine.rank(candidates);
      expect(
        second.ranked.map(
          (item) => (item.destinationId, item.recommendationScore),
        ),
        first.ranked.map(
          (item) => (item.destinationId, item.recommendationScore),
        ),
      );
    });

    test('returns empty ranked and excluded lists for empty candidates', () {
      final result = testEngine().rank(const <CarsCandidate>[]);
      expect(result.ranked, isEmpty);
      expect(result.excluded, isEmpty);
    });

    test('requires exactly all six weights', () {
      final incomplete = Map<CarsCriterion, double>.from(testWeights)
        ..remove(CarsCriterion.availableTravelTimeCompatibility);
      expect(() => testEngine(weights: incomplete), throwsArgumentError);
    });
  });
}
