import 'dart:math';

import '../algorithms/cars_assessment_input_preparer.dart';
import '../algorithms/cars_engine.dart';
import '../models/cars_models.dart';
import '../models/destination_record.dart';
import '../models/itinerary_draft.dart';

/// Complete output required before the existing CARS review page can open.
/// Implementations must supply real destination records and all six approved
/// criterion scores using an approved scoring and eligibility policy.
class CarsRecommendationPackage {
  final CarsRankingResult ranking;
  final List<DestinationRecord> destinations;
  final CarsRunReference runReference;
  final Map<String, CarsPreparedAssessmentInputs> assessmentInputs;

  CarsRecommendationPackage({
    required this.ranking,
    required List<DestinationRecord> destinations,
    required this.runReference,
    Map<String, CarsPreparedAssessmentInputs> assessmentInputs = const {},
  }) : destinations = List.unmodifiable(destinations),
       assessmentInputs = Map.unmodifiable(assessmentInputs);
}

abstract interface class CarsRecommendationProvider {
  Future<CarsRecommendationPackage> recommend(TripConfiguration trip);
}

/// Production default until verified source adapters and an approved CARS
/// scoring/weight policy are connected. It deliberately returns no scores.
class UnavailableCarsRecommendationProvider
    implements CarsRecommendationProvider {
  const UnavailableCarsRecommendationProvider();

  @override
  Future<CarsRecommendationPackage> recommend(TripConfiguration trip) async {
    throw const CarsRecommendationUnavailableException(
      'System-generated recommendations are unavailable. The app does not yet '
      'have a verified provider for all six CARS criteria and an approved '
      'scoring/weight configuration. No substitute scores were generated.',
    );
  }
}

/// Input assembled by source adapters. Eligibility facts remain separate from
/// the six criterion assessments and are evaluated by the CARS engine.
class CarsRecommendationEligibilityInput {
  final bool existsInDataset;
  final String? approvalStatus;
  final String? accreditationStatus;
  final bool accreditationRequired;
  final Set<String> supportedSuitabilityCodes;
  final Set<String> requiredSuitabilityCodes;

  CarsRecommendationEligibilityInput({
    required this.existsInDataset,
    required this.approvalStatus,
    required this.accreditationStatus,
    this.accreditationRequired = true,
    Set<String> supportedSuitabilityCodes = const {},
    Set<String> requiredSuitabilityCodes = const {},
  }) : supportedSuitabilityCodes = Set.unmodifiable(supportedSuitabilityCodes),
       requiredSuitabilityCodes = Set.unmodifiable(requiredSuitabilityCodes);
}

class CarsRecommendationAssessmentRecord {
  final CarsAssessmentPreparationInput assessmentInput;
  final CarsRecommendationEligibilityInput eligibility;

  const CarsRecommendationAssessmentRecord({
    required this.assessmentInput,
    required this.eligibility,
  });
}

/// Injectable source boundary for verified destination records and the
/// existing six typed criterion assessments. This adapter performs no data
/// fetching itself and contains no production scoring policy or weights.
abstract interface class CarsRecommendationAssessmentSource {
  Future<List<CarsRecommendationAssessmentRecord>> loadAssessments(
    TripConfiguration trip,
  );
}

/// Connects assessment-source output -> evidence preparation -> optional
/// approved scoring policy -> eligibility and existing CARS ranker. With no
/// policy, every numeric criterion score remains null, so eligible candidates
/// are returned by the existing engine as insufficientData and none rank.
class PreparedCarsRecommendationProvider implements CarsRecommendationProvider {
  final CarsRecommendationAssessmentSource source;
  final CarsRecommendationEngine engine;
  final CarsAssessmentInputPreparer preparer;
  final CarsCriterionScoringPolicyApplier scoringPolicyApplier;
  final CarsApprovedCriterionScoringPolicy? scoringPolicy;
  final String Function() createRunId;

  PreparedCarsRecommendationProvider({
    required this.source,
    required this.engine,
    this.preparer = const CarsAssessmentInputPreparer(),
    this.scoringPolicyApplier = const CarsCriterionScoringPolicyApplier(),
    this.scoringPolicy,
    String Function()? createRunId,
  }) : createRunId = createRunId ?? _newUuid;

  @override
  Future<CarsRecommendationPackage> recommend(TripConfiguration trip) async {
    final records = await source.loadAssessments(trip);
    final ids = <String>{};
    final candidates = <CarsCandidate>[];
    final destinations = <DestinationRecord>[];
    final preparedById = <String, CarsPreparedAssessmentInputs>{};
    for (final record in records) {
      final raw = record.assessmentInput;
      final destination = raw.destination;
      if (destination.id.trim().isEmpty || !ids.add(destination.id)) {
        throw const CarsRecommendationUnavailableException(
          'The CARS source returned an empty or duplicate destination identity.',
        );
      }
      final prepared = scoringPolicyApplier.apply(
        preparer.prepare(raw),
        policy: scoringPolicy,
      );
      final eligibility = record.eligibility;
      candidates.add(
        CarsCandidate(
          destinationId: destination.id,
          destinationName: destination.name,
          existsInDataset: eligibility.existsInDataset,
          approvalStatus: eligibility.approvalStatus,
          accreditationStatus: eligibility.accreditationStatus,
          accreditationRequired: eligibility.accreditationRequired,
          supportedSuitabilityCodes: eligibility.supportedSuitabilityCodes,
          requiredSuitabilityCodes: eligibility.requiredSuitabilityCodes,
          criterionScores: prepared.criterionScores,
        ),
      );
      destinations.add(destination);
      preparedById[destination.id] = prepared;
    }
    return CarsRecommendationPackage(
      ranking: engine.rank(candidates),
      destinations: destinations,
      runReference: CarsRunReference(createRunId()),
      assessmentInputs: preparedById,
    );
  }
}

String _newUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final value = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

class CarsRecommendationUnavailableException implements Exception {
  final String message;

  const CarsRecommendationUnavailableException(this.message);

  @override
  String toString() => message;
}
