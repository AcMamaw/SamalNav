import 'price_info.dart';

/// The six approved CARS criteria. Their order is stable for explanations and
/// deterministic weighted-score accumulation.
enum CarsCriterion {
  interestActivityMatch,
  publicDestinationRating,
  weatherSuitability,
  budgetCompatibility,
  travelDistanceSuitability,
  availableTravelTimeCompatibility,
}

/// Raw contextual inputs are kept separate from normalized criterion scores.
/// These values are descriptive only; CARS does not infer score formulas from
/// them. A separately approved scoring policy must produce 0-100 scores.
class CarsRawContext {
  final Set<String> touristInterestCodes;
  final Set<String> destinationActivityCodes;
  final double? publicRating;
  final String? publicRatingSource;
  final DateTime? publicRatingRetrievedAt;
  final DateTime? publicRatingFreshUntil;
  final double? touristBudget;
  /// Price provenance is retained; unverified amounts are not scoring inputs.
  final PriceInfo? estimatedDestinationCost;
  final double? routeDistanceKm;
  final double? estimatedRequiredMinutes;
  final double? availableMinutes;
  final Map<String, Object?>? weatherObservation;

  CarsRawContext({
    Set<String> touristInterestCodes = const {},
    Set<String> destinationActivityCodes = const {},
    this.publicRating,
    this.publicRatingSource,
    this.publicRatingRetrievedAt,
    this.publicRatingFreshUntil,
    this.touristBudget,
    this.estimatedDestinationCost,
    this.routeDistanceKm,
    this.estimatedRequiredMinutes,
    this.availableMinutes,
    Map<String, Object?>? weatherObservation,
  }) : touristInterestCodes = Set.unmodifiable(touristInterestCodes),
       destinationActivityCodes = Set.unmodifiable(destinationActivityCodes),
       weatherObservation = weatherObservation == null
           ? null
           : Map.unmodifiable(weatherObservation);
}

/// Candidate data supplied by an approved destination repository and a
/// separately defined score provider. No Supabase schema is assumed here.
class CarsCandidate {
  final String destinationId;
  final String destinationName;
  final bool existsInDataset;
  final String? approvalStatus;
  final String? accreditationStatus;
  final bool accreditationRequired;
  final Set<String> supportedSuitabilityCodes;
  final Set<String> requiredSuitabilityCodes;
  final Map<CarsCriterion, double?> criterionScores;
  final CarsRawContext? rawContext;

  CarsCandidate({
    required this.destinationId,
    required this.destinationName,
    required this.existsInDataset,
    required this.approvalStatus,
    required this.accreditationStatus,
    this.accreditationRequired = true,
    Set<String> supportedSuitabilityCodes = const {},
    Set<String> requiredSuitabilityCodes = const {},
    required Map<CarsCriterion, double?> criterionScores,
    this.rawContext,
  }) : supportedSuitabilityCodes = Set.unmodifiable(supportedSuitabilityCodes),
       requiredSuitabilityCodes = Set.unmodifiable(requiredSuitabilityCodes),
       criterionScores = Map.unmodifiable(criterionScores);
}

/// Configurable accepted states. The project has not approved canonical
/// accreditation/status values, so callers must supply them explicitly.
class CarsEligibilityPolicy {
  final Set<String> approvedStatuses;
  final Set<String> accreditedStatuses;

  CarsEligibilityPolicy({
    required Set<String> approvedStatuses,
    required Set<String> accreditedStatuses,
  }) : approvedStatuses = Set.unmodifiable(
         approvedStatuses.map((value) => value.trim().toLowerCase()),
       ),
       accreditedStatuses = Set.unmodifiable(
         accreditedStatuses.map((value) => value.trim().toLowerCase()),
       ) {
    if (this.approvedStatuses.isEmpty) {
      throw ArgumentError.value(
        approvedStatuses,
        'approvedStatuses',
        'Must not be empty.',
      );
    }
    if (this.accreditedStatuses.isEmpty) {
      throw ArgumentError.value(
        accreditedStatuses,
        'accreditedStatuses',
        'Must not be empty.',
      );
    }
  }
}

class CarsEligibilityResult {
  final bool isEligible;
  final List<String> reasons;

  CarsEligibilityResult({
    required this.isEligible,
    required List<String> reasons,
  }) : reasons = List.unmodifiable(reasons);
}

enum CarsCandidateOutcome { ranked, ineligible, insufficientData }

class CarsCandidateResult {
  final String destinationId;
  final String destinationName;
  final CarsCandidateOutcome outcome;
  final double? recommendationScore;
  final Map<CarsCriterion, double>? criterionScores;
  final Map<CarsCriterion, double>? weightedContributions;
  final CarsEligibilityResult eligibility;
  final List<String> missingCriteria;
  final String explanation;

  CarsCandidateResult({
    required this.destinationId,
    required this.destinationName,
    required this.outcome,
    required this.recommendationScore,
    required Map<CarsCriterion, double>? criterionScores,
    required Map<CarsCriterion, double>? weightedContributions,
    required this.eligibility,
    required List<String> missingCriteria,
    required this.explanation,
  }) : criterionScores = criterionScores == null
           ? null
           : Map.unmodifiable(criterionScores),
       weightedContributions = weightedContributions == null
           ? null
           : Map.unmodifiable(weightedContributions),
       missingCriteria = List.unmodifiable(missingCriteria);
}

class CarsRankingResult {
  final List<CarsCandidateResult> ranked;
  final List<CarsCandidateResult> excluded;

  CarsRankingResult({
    required List<CarsCandidateResult> ranked,
    required List<CarsCandidateResult> excluded,
  }) : ranked = List.unmodifiable(ranked),
       excluded = List.unmodifiable(excluded);
}
