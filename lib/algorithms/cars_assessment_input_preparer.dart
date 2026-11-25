import '../models/cars_models.dart';
import '../models/destination_record.dart';
import '../services/open_weather_map_service.dart';
import 'cars_budget_assessment.dart';
import 'cars_interest_activity_matcher.dart';
import 'cars_travel_assessment.dart';

enum CarsAssessmentInputStatus {
  available,
  insufficientData,
  unavailable,
  invalid,
  stale,
  unsupported,
  notApplicable,
}

enum CarsScorePreparationStatus {
  available,
  noApprovedRule,
  evidenceNotScoreable,
  ruleReturnedNoScore,
  invalidRuleOutput,
}

/// Raw, typed evidence for one criterion, plus an optional score produced by
/// an injected approved policy. The preparation layer itself defines no
/// normalization formula, threshold, weight, or default score.
class CarsPreparedCriterionInput {
  final CarsCriterion criterion;
  final CarsAssessmentInputStatus inputStatus;
  final Object? evidence;
  final String explanation;
  final String? approvedRuleReference;
  final CarsScorePreparationStatus scoreStatus;
  final double? criterionScore;

  const CarsPreparedCriterionInput({
    required this.criterion,
    required this.inputStatus,
    required this.evidence,
    required this.explanation,
    required this.approvedRuleReference,
    required this.scoreStatus,
    required this.criterionScore,
  });
}

class CarsAssessmentPreparationInput {
  final DestinationRecord destination;
  final CarsInterestActivityMatchAssessment? interestActivityMatch;
  final bool preferencesConfirmed;
  final WeatherForecastResult? weather;
  final CarsBudgetAssessment? budget;
  final CarsTravelAssessment? travel;
  final DateTime assessedAt;

  const CarsAssessmentPreparationInput({
    required this.destination,
    required this.interestActivityMatch,
    required this.preferencesConfirmed,
    required this.weather,
    required this.budget,
    required this.travel,
    required this.assessedAt,
  });
}

/// Implementations must identify the separately approved scoring rule used
/// for a criterion. No implementation is provided by SAMAL NAV because no
/// normalization rules for these raw assessments have been approved here.
abstract interface class CarsApprovedCriterionScoringPolicy {
  String? approvedRuleReferenceFor(CarsCriterion criterion);

  double? scoreFor({
    required CarsCriterion criterion,
    required Object evidence,
  });
}

class CarsPreparedAssessmentInputs {
  final String destinationId;
  final String destinationName;
  final Map<CarsCriterion, CarsPreparedCriterionInput> criteria;

  CarsPreparedAssessmentInputs({
    required this.destinationId,
    required this.destinationName,
    required Map<CarsCriterion, CarsPreparedCriterionInput> criteria,
  }) : criteria = Map.unmodifiable(criteria);

  /// Null values intentionally remain null so CarsRecommendationEngine
  /// reports insufficient data instead of treating missing inputs as zero or
  /// redistributing weights.
  Map<CarsCriterion, double?> get criterionScores => Map.unmodifiable({
    for (final criterion in CarsCriterion.values)
      criterion: criteria[criterion]?.criterionScore,
  });

  bool get hasAllCriterionScores => CarsCriterion.values.every(
    (criterion) => criterionScores[criterion] != null,
  );
}

class CarsAssessmentInputPreparer {
  const CarsAssessmentInputPreparer();

  CarsPreparedAssessmentInputs prepare(CarsAssessmentPreparationInput input) {
    final evidence = <CarsCriterion, _EvidenceState>{
      CarsCriterion.interestActivityMatch: _interestEvidence(input),
      CarsCriterion.publicDestinationRating: _ratingEvidence(input),
      CarsCriterion.weatherSuitability: _weatherEvidence(input),
      CarsCriterion.budgetCompatibility: _budgetEvidence(input),
      CarsCriterion.travelDistanceSuitability: _travelDistanceEvidence(input),
      CarsCriterion.availableTravelTimeCompatibility: _availableTimeEvidence(
        input,
      ),
    };
    return CarsPreparedAssessmentInputs(
      destinationId: input.destination.id,
      destinationName: input.destination.name,
      criteria: {
        for (final criterion in CarsCriterion.values)
          criterion: _prepareCriterion(criterion, evidence[criterion]!),
      },
    );
  }

  CarsPreparedCriterionInput _prepareCriterion(
    CarsCriterion criterion,
    _EvidenceState state,
  ) => CarsPreparedCriterionInput(
    criterion: criterion,
    inputStatus: state.status,
    evidence: state.evidence,
    explanation: state.explanation,
    approvedRuleReference: null,
    scoreStatus: state.status == CarsAssessmentInputStatus.available
        ? CarsScorePreparationStatus.noApprovedRule
        : CarsScorePreparationStatus.evidenceNotScoreable,
    criterionScore: null,
  );

  _EvidenceState _interestEvidence(CarsAssessmentPreparationInput input) {
    final match = input.interestActivityMatch;
    if (match == null) {
      return const _EvidenceState(
        status: CarsAssessmentInputStatus.unavailable,
        explanation: 'Interest/activity assessment is unavailable.',
      );
    }
    switch (match.status) {
      case CarsInterestActivityMatchStatus.noPreferenceSelected:
        return _EvidenceState(
          status: CarsAssessmentInputStatus.notApplicable,
          evidence: match,
          explanation: 'No specific tourist preference was selected.',
        );
      case CarsInterestActivityMatchStatus.mappingUnavailable:
        return _EvidenceState(
          status: CarsAssessmentInputStatus.unavailable,
          evidence: match,
          explanation:
              'No authoritative preference-to-activity mapping is available.',
        );
      case CarsInterestActivityMatchStatus.unsupportedPreferenceIdentifiers:
        return _EvidenceState(
          status: CarsAssessmentInputStatus.unsupported,
          evidence: match,
          explanation: 'One or more preference identifiers are unsupported.',
        );
      case CarsInterestActivityMatchStatus.activityCategoriesUnavailable:
        return _EvidenceState(
          status: CarsAssessmentInputStatus.unavailable,
          evidence: match,
          explanation: 'Destination activity-category evidence is unavailable.',
        );
      case CarsInterestActivityMatchStatus.activityRelationshipsIncomplete:
        return _EvidenceState(
          status: CarsAssessmentInputStatus.insufficientData,
          evidence: match,
          explanation:
              'Destination activity-category relationships are incomplete.',
        );
      case CarsInterestActivityMatchStatus.duplicateActivityIdentifiers:
      case CarsInterestActivityMatchStatus.invalidActivityEvidence:
        return _EvidenceState(
          status: CarsAssessmentInputStatus.invalid,
          evidence: match,
          explanation:
              'Destination activity identifiers are invalid or duplicated.',
        );
      case CarsInterestActivityMatchStatus.inactiveActivityRecords:
        return _EvidenceState(
          status: CarsAssessmentInputStatus.insufficientData,
          evidence: match,
          explanation:
              'Inactive activity applicability has no approved CARS rule.',
        );
      case CarsInterestActivityMatchStatus.staleActivityEvidence:
        return _EvidenceState(
          status: CarsAssessmentInputStatus.stale,
          evidence: match,
          explanation: 'Destination activity evidence is stale.',
        );
      case CarsInterestActivityMatchStatus.matched:
      case CarsInterestActivityMatchStatus.noMatch:
        if (!input.preferencesConfirmed) {
          return _EvidenceState(
            status: CarsAssessmentInputStatus.insufficientData,
            evidence: match,
            explanation:
                'Preference values are not confirmed for recommendation use.',
          );
        }
        return _EvidenceState(
          status: CarsAssessmentInputStatus.available,
          evidence: match,
          explanation:
              'Categorical preference/activity match assessment is available.',
        );
    }
  }

  _EvidenceState _ratingEvidence(CarsAssessmentPreparationInput input) {
    final destination = input.destination;
    if (destination.ratingDataState == DestinationRatingDataState.invalid) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.invalid,
        evidence: destination,
        explanation: 'Public rating value is invalid.',
      );
    }
    if (destination.ratingDataState == DestinationRatingDataState.missing ||
        destination.rating == null) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.unavailable,
        evidence: destination,
        explanation: 'Public rating is missing.',
      );
    }
    final rating = destination.rating!;
    if (!rating.isFinite || rating < 0 || rating > 5) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.invalid,
        evidence: destination,
        explanation: 'Public rating is outside the recorded 0-5 range.',
      );
    }
    if (destination.ratingVerification !=
        DestinationRatingVerification.verified) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.insufficientData,
        evidence: destination,
        explanation: 'Public rating is not explicitly verified.',
      );
    }
    if (destination.source == DestinationRecordSource.fallback) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.unsupported,
        evidence: destination,
        explanation:
            'Bundled fallback ratings are not verified public-rating evidence.',
      );
    }
    if (destination.ratingSource == null ||
        destination.ratingSource!.trim().isEmpty ||
        destination.ratingRetrievedAt == null ||
        destination.ratingFreshUntil == null) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.insufficientData,
        evidence: destination,
        explanation:
            'Verified rating source and freshness metadata are incomplete.',
      );
    }
    if (destination.ratingRetrievedAt!.isAfter(input.assessedAt)) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.invalid,
        evidence: destination,
        explanation: 'Rating retrieval timestamp is in the future.',
      );
    }
    if (!destination.ratingFreshUntil!.isAfter(input.assessedAt)) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.stale,
        evidence: destination,
        explanation: 'Verified public rating has expired.',
      );
    }
    return _EvidenceState(
      status: CarsAssessmentInputStatus.available,
      evidence: destination,
      explanation:
          'Verified public rating and freshness evidence are available.',
    );
  }

  _EvidenceState _weatherEvidence(CarsAssessmentPreparationInput input) {
    final weather = input.weather;
    if (weather == null) {
      return const _EvidenceState(
        status: CarsAssessmentInputStatus.unavailable,
        explanation: 'Weather forecast evidence is unavailable.',
      );
    }
    final status = switch (weather.coverage) {
      WeatherForecastCoverage.available => CarsAssessmentInputStatus.available,
      WeatherForecastCoverage.partial =>
        CarsAssessmentInputStatus.insufficientData,
      WeatherForecastCoverage.stale => CarsAssessmentInputStatus.stale,
      WeatherForecastCoverage.unavailable =>
        CarsAssessmentInputStatus.unavailable,
    };
    return _EvidenceState(
      status: status,
      evidence: weather,
      explanation: 'Weather forecast coverage: ${weather.coverage.name}.',
    );
  }

  _EvidenceState _budgetEvidence(CarsAssessmentPreparationInput input) {
    final budget = input.budget;
    if (budget == null) {
      return const _EvidenceState(
        status: CarsAssessmentInputStatus.unavailable,
        explanation: 'Budget assessment is unavailable.',
      );
    }
    final status = switch (budget.status) {
      BudgetAssessmentStatus.withinBudget ||
      BudgetAssessmentStatus.overBudget => CarsAssessmentInputStatus.available,
      BudgetAssessmentStatus.insufficientData =>
        CarsAssessmentInputStatus.insufficientData,
    };
    return _EvidenceState(
      status: status,
      evidence: budget,
      explanation: budget.status == BudgetAssessmentStatus.insufficientData
          ? 'Budget assessment is incomplete: ${budget.missingInformation.join(' ')}'
          : 'Budget compatibility assessment: ${budget.status.name}.',
    );
  }

  _EvidenceState _travelDistanceEvidence(CarsAssessmentPreparationInput input) {
    final travel = input.travel;
    if (travel == null) {
      return const _EvidenceState(
        status: CarsAssessmentInputStatus.unavailable,
        explanation:
            'Provider-backed travel-distance assessment is unavailable.',
      );
    }
    final legs = travel.days.expand((day) => day.legs).toList();
    return _travelState(
      travel,
      legs,
      hasValues: travel.days.every((day) => day.totalRouteDistanceKm != null),
      explanation: 'Provider-backed route-distance evidence is incomplete.',
    );
  }

  _EvidenceState _availableTimeEvidence(CarsAssessmentPreparationInput input) {
    final travel = input.travel;
    if (travel == null) {
      return const _EvidenceState(
        status: CarsAssessmentInputStatus.unavailable,
        explanation: 'Available-travel-time assessment is unavailable.',
      );
    }
    final legs = travel.days.expand((day) => day.legs).toList();
    final hasValues = travel.days.every(
      (day) =>
          day.totalEstimatedTravelMinutes != null &&
          day.availableMinutes != null &&
          day.timeCompatibility != AvailableTimeCompatibility.unknown,
    );
    return _travelState(
      travel,
      legs,
      hasValues: hasValues,
      explanation: 'Provider-backed travel-time comparison is incomplete.',
    );
  }

  _EvidenceState _travelState(
    CarsTravelAssessment travel,
    List<TravelLegAssessment> legs, {
    required bool hasValues,
    required String explanation,
  }) {
    if (legs.isEmpty) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.unavailable,
        evidence: travel,
        explanation: explanation,
      );
    }
    if (legs.any((leg) => leg.state == TravelEstimateState.stale)) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.stale,
        evidence: travel,
        explanation: explanation,
      );
    }
    if (travel.hasCompleteRouteData && hasValues) {
      return _EvidenceState(
        status: CarsAssessmentInputStatus.available,
        evidence: travel,
        explanation: 'Fresh provider-backed travel assessment is available.',
      );
    }
    final anyRouteValue = travel.days.any(
      (day) =>
          day.totalRouteDistanceKm != null ||
          day.totalEstimatedTravelMinutes != null,
    );
    return _EvidenceState(
      status: anyRouteValue
          ? CarsAssessmentInputStatus.insufficientData
          : CarsAssessmentInputStatus.unavailable,
      evidence: travel,
      explanation: explanation,
    );
  }
}

/// Applies a separately approved normalization policy to prepared evidence.
/// It never scores unavailable, stale, invalid, unsupported, or incomplete
/// evidence, and it rejects malformed scores before they reach the ranker.
class CarsCriterionScoringPolicyApplier {
  const CarsCriterionScoringPolicyApplier();

  CarsPreparedAssessmentInputs apply(
    CarsPreparedAssessmentInputs prepared, {
    required CarsApprovedCriterionScoringPolicy? policy,
  }) {
    final output = <CarsCriterion, CarsPreparedCriterionInput>{};
    for (final criterion in CarsCriterion.values) {
      final input = prepared.criteria[criterion]!;
      if (input.inputStatus != CarsAssessmentInputStatus.available) {
        output[criterion] = CarsPreparedCriterionInput(
          criterion: criterion,
          inputStatus: input.inputStatus,
          evidence: input.evidence,
          explanation: input.explanation,
          approvedRuleReference: null,
          scoreStatus: CarsScorePreparationStatus.evidenceNotScoreable,
          criterionScore: null,
        );
        continue;
      }
      final reference = policy?.approvedRuleReferenceFor(criterion)?.trim();
      if (policy == null || reference == null || reference.isEmpty) {
        output[criterion] = CarsPreparedCriterionInput(
          criterion: criterion,
          inputStatus: input.inputStatus,
          evidence: input.evidence,
          explanation: input.explanation,
          approvedRuleReference: null,
          scoreStatus: CarsScorePreparationStatus.noApprovedRule,
          criterionScore: null,
        );
        continue;
      }
      final score = policy.scoreFor(
        criterion: criterion,
        evidence: input.evidence!,
      );
      if (score == null) {
        output[criterion] = CarsPreparedCriterionInput(
          criterion: criterion,
          inputStatus: input.inputStatus,
          evidence: input.evidence,
          explanation: input.explanation,
          approvedRuleReference: reference,
          scoreStatus: CarsScorePreparationStatus.ruleReturnedNoScore,
          criterionScore: null,
        );
        continue;
      }
      if (!CarsScoreContract.accepts(score)) {
        output[criterion] = CarsPreparedCriterionInput(
          criterion: criterion,
          inputStatus: CarsAssessmentInputStatus.invalid,
          evidence: input.evidence,
          explanation:
              'The approved scoring policy returned a value outside '
              '${CarsScoreContract.minimum}-${CarsScoreContract.maximum}.',
          approvedRuleReference: reference,
          scoreStatus: CarsScorePreparationStatus.invalidRuleOutput,
          criterionScore: null,
        );
        continue;
      }
      output[criterion] = CarsPreparedCriterionInput(
        criterion: criterion,
        inputStatus: input.inputStatus,
        evidence: input.evidence,
        explanation: input.explanation,
        approvedRuleReference: reference,
        scoreStatus: CarsScorePreparationStatus.available,
        criterionScore: score,
      );
    }
    return CarsPreparedAssessmentInputs(
      destinationId: prepared.destinationId,
      destinationName: prepared.destinationName,
      criteria: output,
    );
  }
}

class _EvidenceState {
  const _EvidenceState({
    required this.status,
    required this.explanation,
    this.evidence,
  });

  final CarsAssessmentInputStatus status;
  final Object? evidence;
  final String explanation;
}
