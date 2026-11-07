import '../models/cars_models.dart';

/// Separately evaluates dataset, approval, accreditation, and group
/// suitability eligibility. Eligibility never contributes to the score.
class CarsEligibilityEvaluator {
  final CarsEligibilityPolicy policy;

  const CarsEligibilityEvaluator(this.policy);

  CarsEligibilityResult evaluate(CarsCandidate candidate) {
    final reasons = <String>[];
    if (!candidate.existsInDataset) {
      reasons.add('Destination is not present in the SAMAL NAV dataset.');
    }

    final approvalStatus = candidate.approvalStatus?.trim().toLowerCase();
    if (approvalStatus == null ||
        !policy.approvedStatuses.contains(approvalStatus)) {
      reasons.add('Destination approval status is missing or not accepted.');
    }

    if (candidate.accreditationRequired) {
      final accreditationStatus = candidate.accreditationStatus
          ?.trim()
          .toLowerCase();
      if (accreditationStatus == null ||
          !policy.accreditedStatuses.contains(accreditationStatus)) {
        reasons.add(
          'Required accreditation status is missing or not accepted.',
        );
      }
    }

    final unsupportedRequirements = candidate.requiredSuitabilityCodes
        .difference(candidate.supportedSuitabilityCodes);
    if (unsupportedRequirements.isNotEmpty) {
      reasons.add(
        'Recorded characteristics do not satisfy declared requirements: '
        '${unsupportedRequirements.toList()..sort()}.',
      );
    }

    return CarsEligibilityResult(isEligible: reasons.isEmpty, reasons: reasons);
  }
}

/// Weighted ranker for already-normalized CARS criterion scores.
///
/// Scores and weights are validated without normalization or redistribution.
/// The score is the sum of six `weight * score` contributions, on a 0-100
/// scale. Equal totals are ordered by destination ID, then name, ascending.
class CarsRecommendationEngine {
  /// Absolute tolerance used only when validating the sum of weights.
  static const double weightSumTolerance = 1e-9;

  final Map<CarsCriterion, double> weights;
  final CarsEligibilityEvaluator eligibilityEvaluator;

  CarsRecommendationEngine({
    required Map<CarsCriterion, double> weights,
    required this.eligibilityEvaluator,
  }) : weights = _validatedWeights(weights);

  static Map<CarsCriterion, double> _validatedWeights(
    Map<CarsCriterion, double> input,
  ) {
    if (input.length != CarsCriterion.values.length ||
        !CarsCriterion.values.every(input.containsKey)) {
      throw ArgumentError.value(
        input,
        'weights',
        'Exactly one weight for each of the six approved criteria is required.',
      );
    }
    for (final criterion in CarsCriterion.values) {
      final weight = input[criterion]!;
      if (!weight.isFinite || weight < 0) {
        throw ArgumentError.value(
          weight,
          criterion.name,
          'Weight must be finite and nonnegative.',
        );
      }
    }
    final sum = CarsCriterion.values.fold<double>(
      0,
      (total, criterion) => total + input[criterion]!,
    );
    if ((sum - 1).abs() > weightSumTolerance) {
      throw ArgumentError.value(
        sum,
        'weights',
        'Weights must sum to 1 within $weightSumTolerance.',
      );
    }
    return Map.unmodifiable({
      for (final criterion in CarsCriterion.values)
        criterion: input[criterion]!,
    });
  }

  CarsRankingResult rank(Iterable<CarsCandidate> candidates) {
    final ranked = <CarsCandidateResult>[];
    final excluded = <CarsCandidateResult>[];

    for (final candidate in candidates) {
      final eligibility = eligibilityEvaluator.evaluate(candidate);
      if (!eligibility.isEligible) {
        excluded.add(
          CarsCandidateResult(
            destinationId: candidate.destinationId,
            destinationName: candidate.destinationName,
            outcome: CarsCandidateOutcome.ineligible,
            recommendationScore: null,
            criterionScores: null,
            weightedContributions: null,
            eligibility: eligibility,
            missingCriteria: const [],
            explanation: eligibility.reasons.join(' '),
          ),
        );
        continue;
      }

      final scores = <CarsCriterion, double>{};
      for (final criterion in CarsCriterion.values) {
        final score = candidate.criterionScores[criterion];
        if (score == null) continue;
        if (!score.isFinite || score < 0 || score > 100) {
          throw ArgumentError.value(
            score,
            '${candidate.destinationId}.${criterion.name}',
            'Criterion score must be finite and between 0 and 100.',
          );
        }
        scores[criterion] = score;
      }

      final missing = CarsCriterion.values
          .where((criterion) => candidate.criterionScores[criterion] == null)
          .map((criterion) => criterion.name)
          .toList();
      if (missing.isNotEmpty) {
        excluded.add(
          CarsCandidateResult(
            destinationId: candidate.destinationId,
            destinationName: candidate.destinationName,
            outcome: CarsCandidateOutcome.insufficientData,
            recommendationScore: null,
            criterionScores: null,
            weightedContributions: null,
            eligibility: eligibility,
            missingCriteria: missing,
            explanation:
                'Candidate is eligible but lacks required scores for: ${missing.join(', ')}.',
          ),
        );
        continue;
      }

      final contributions = <CarsCriterion, double>{};
      for (final criterion in CarsCriterion.values) {
        final score = scores[criterion]!;
        contributions[criterion] = weights[criterion]! * score;
      }

      final total = CarsCriterion.values.fold<double>(
        0,
        (sum, criterion) => sum + contributions[criterion]!,
      );
      ranked.add(
        CarsCandidateResult(
          destinationId: candidate.destinationId,
          destinationName: candidate.destinationName,
          outcome: CarsCandidateOutcome.ranked,
          recommendationScore: total,
          criterionScores: scores,
          weightedContributions: contributions,
          eligibility: eligibility,
          missingCriteria: const [],
          explanation: _explanation(scores, contributions, total),
        ),
      );
    }

    ranked.sort((a, b) {
      final scoreOrder = b.recommendationScore!.compareTo(
        a.recommendationScore!,
      );
      if (scoreOrder != 0) return scoreOrder;
      final idOrder = a.destinationId.compareTo(b.destinationId);
      if (idOrder != 0) return idOrder;
      return a.destinationName.compareTo(b.destinationName);
    });
    excluded.sort((a, b) {
      final idOrder = a.destinationId.compareTo(b.destinationId);
      return idOrder != 0
          ? idOrder
          : a.destinationName.compareTo(b.destinationName);
    });

    return CarsRankingResult(ranked: ranked, excluded: excluded);
  }

  String _explanation(
    Map<CarsCriterion, double> scores,
    Map<CarsCriterion, double> contributions,
    double total,
  ) {
    final topCriterion = CarsCriterion.values.reduce(
      (best, candidate) =>
          contributions[candidate]! > contributions[best]! ? candidate : best,
    );
    return 'Recommendation score ${total.toStringAsFixed(2)} / 100. '
        'Largest weighted contribution: ${topCriterion.name} '
        '(${scores[topCriterion]!.toStringAsFixed(2)} x '
        '${weights[topCriterion]!.toStringAsFixed(4)} = '
        '${contributions[topCriterion]!.toStringAsFixed(2)}).';
  }
}
