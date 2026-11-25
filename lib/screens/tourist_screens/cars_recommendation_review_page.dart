import 'package:flutter/material.dart';

import '../../algorithms/cars_assessment_input_preparer.dart';
import '../../algorithms/cars_budget_assessment.dart';
import '../../algorithms/cars_interest_activity_matcher.dart';
import '../../algorithms/cars_travel_assessment.dart';
import '../../algorithms/system_generated_draft_builder.dart';
import '../../models/cars_models.dart';
import '../../models/destination_record.dart';
import '../../models/itinerary_draft.dart';
import '../../services/open_weather_map_service.dart';
import 'system_generated_draft_review_page.dart';

/// Lets a tourist review and select actual CARS results before optimization.
/// Ranking, scoring, and data acquisition must happen before this page opens.
class CarsRecommendationReviewPage extends StatefulWidget {
  final CarsRankingResult ranking;
  final List<DestinationRecord> destinations;
  final Map<String, CarsPreparedAssessmentInputs> assessmentInputs;
  final TripConfiguration trip;
  final CarsRunReference carsRunReference;

  const CarsRecommendationReviewPage({
    super.key,
    required this.ranking,
    required this.destinations,
    this.assessmentInputs = const {},
    required this.trip,
    required this.carsRunReference,
  });

  @override
  State<CarsRecommendationReviewPage> createState() =>
      _CarsRecommendationReviewPageState();
}

class _CarsRecommendationReviewPageState
    extends State<CarsRecommendationReviewPage> {
  final Set<String> _selectedIds = <String>{};
  final Map<String, int> _assignedDays = <String, int>{};
  String? _buildError;

  static const _criterionLabels = <CarsCriterion, String>{
    CarsCriterion.interestActivityMatch:
        'Tourist preference / interest and activity match',
    CarsCriterion.publicDestinationRating: 'Public destination rating',
    CarsCriterion.weatherSuitability: 'Weather suitability',
    CarsCriterion.budgetCompatibility: 'Budget compatibility',
    CarsCriterion.travelDistanceSuitability: 'Travel distance',
    CarsCriterion.availableTravelTimeCompatibility:
        'Available travel time compatibility',
  };

  void _toggleSelection(String destinationId, bool selected) {
    setState(() {
      _buildError = null;
      if (selected) {
        _selectedIds.add(destinationId);
        if (widget.trip.durationDays > 1) {
          _assignedDays.remove(destinationId);
        }
      } else {
        _selectedIds.remove(destinationId);
        _assignedDays.remove(destinationId);
      }
    });
  }

  Future<void> _continueToDraftReview() async {
    try {
      final draft = const SystemGeneratedDraftBuilder().build(
        ranking: widget.ranking,
        selectedDestinationIds: _selectedIds.toList(),
        assignedDays: _assignedDays,
        destinations: widget.destinations,
        trip: widget.trip,
        carsRunReference: widget.carsRunReference,
      );
      final reviewed = await Navigator.of(context).push<ItineraryDraft>(
        MaterialPageRoute(
          builder: (_) => SystemGeneratedDraftReviewPage(draft: draft),
        ),
      );
      if (reviewed != null && mounted) {
        Navigator.of(context).pop(reviewed);
      }
    } on Object catch (error) {
      setState(
        () =>
            _buildError = error.toString().replaceFirst('ArgumentError: ', ''),
      );
    }
  }

  bool get _canContinue =>
      _selectedIds.isNotEmpty &&
      (widget.trip.durationDays == 1 ||
          _selectedIds.every(_assignedDays.containsKey));

  @override
  Widget build(BuildContext context) {
    final selectableIds = widget.destinations
        .where(
          (item) =>
              item.source == DestinationRecordSource.database &&
              item.isActive &&
              item.isVerified,
        )
        .map((item) => item.id)
        .toSet();
    final excluded = widget.ranking.excluded;

    return Scaffold(
      appBar: AppBar(title: const Text('Review CARS recommendations')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Context-Aware Recommendation System (CARS)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Review the trip details and recommendations. Scores and '
                      'data limitations below come from this CARS result; '
                      'missing values are not filled or reweighted here. '
                      'Evidence details are shown when the provider supplies '
                      'them. The result does not retain a saved preference '
                      'profile snapshot; confirm the intended preferences. '
                      'Missing evidence is not scored or reweighted.',
                    ),
                  ],
                ),
              ),
            ),
            _buildTripContext(),
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 6),
              child: Text(
                'Recommendations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            if (widget.ranking.ranked.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('No ranked recommendations are available.'),
                  subtitle: Text(
                    'Check the destination data and CARS scoring inputs before trying again.',
                  ),
                ),
              )
            else
              for (final result in widget.ranking.ranked)
                _buildRecommendation(
                  result,
                  isSelectable: selectableIds.contains(result.destinationId),
                ),
            if (excluded.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 18, bottom: 6),
                child: Text(
                  'Not recommended in this result',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              for (final result in excluded) _buildExcluded(result),
            ],
            if (_buildError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _buildError!,
                  key: const Key('cars_draft_error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                'Your selection creates an unoptimized itinerary draft. MO-GA '
                'will not run until you explicitly request optimization later.',
              ),
            ),
            FilledButton.icon(
              key: const Key('continue_cars_draft_review'),
              onPressed: _canContinue ? _continueToDraftReview : null,
              icon: const Icon(Icons.checklist),
              label: const Text('Continue with selected destinations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripContext() {
    final trip = widget.trip;
    final origin = trip.origin;
    return Card(
      child: ListTile(
        key: const Key('cars_trip_context_summary'),
        leading: const Icon(Icons.tune),
        title: const Text('Trip details for this draft'),
        subtitle: Text(
          '${trip.durationDays} day(s) · ${trip.availableHoursPerDay} available hours per day'
          '${trip.startDate == null ? '' : ' · Starts ${_dateLabel(trip.startDate!)}'}'
          '${origin == null ? ' · No starting point supplied' : ' · Starting point: ${origin.label ?? '${origin.latitude}, ${origin.longitude}'}'}',
        ),
      ),
    );
  }

  Widget _buildRecommendation(
    CarsCandidateResult result, {
    required bool isSelectable,
  }) {
    final scores = result.criterionScores ?? const <CarsCriterion, double>{};
    final contributions =
        result.weightedContributions ?? const <CarsCriterion, double>{};
    return Card(
      child: Column(
        children: [
          CheckboxListTile(
            key: Key('cars_select_${result.destinationId}'),
            value: _selectedIds.contains(result.destinationId),
            onChanged: isSelectable
                ? (value) =>
                      _toggleSelection(result.destinationId, value ?? false)
                : null,
            title: Text(result.destinationName),
            subtitle: Text(
              isSelectable
                  ? 'CARS score ${result.recommendationScore?.toStringAsFixed(2) ?? 'unavailable'} / ${CarsScoreContract.maximum.toStringAsFixed(0)}'
                  : 'This recommendation has no verified, active database destination record and cannot be selected.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.explanation),
                const SizedBox(height: 8),
                for (final criterion in CarsCriterion.values)
                  Text(
                    '${_criterionLabels[criterion]}: '
                    '${scores[criterion]?.toStringAsFixed(1) ?? 'missing'}'
                    '${contributions.containsKey(criterion) ? ' (weighted contribution ${contributions[criterion]!.toStringAsFixed(2)})' : ''}',
                  ),
                _buildAssessmentEvidence(result.destinationId),
                if (_selectedIds.contains(result.destinationId) &&
                    widget.trip.durationDays > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DropdownButtonFormField<int>(
                      key: Key('cars_day_${result.destinationId}'),
                      initialValue: _assignedDays[result.destinationId],
                      decoration: const InputDecoration(
                        labelText: 'Assign to itinerary day',
                      ),
                      items: [
                        for (
                          var day = 1;
                          day <= widget.trip.durationDays;
                          day++
                        )
                          DropdownMenuItem(value: day, child: Text('Day $day')),
                      ],
                      onChanged: (day) => setState(() {
                        if (day == null) {
                          _assignedDays.remove(result.destinationId);
                        } else {
                          _assignedDays[result.destinationId] = day;
                        }
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcluded(CarsCandidateResult result) {
    final missingLabels = result.missingCriteria.map((name) {
      for (final entry in _criterionLabels.entries) {
        if (entry.key.name == name) return entry.value;
      }
      return name;
    });
    final limitation = result.outcome == CarsCandidateOutcome.insufficientData
        ? 'Insufficient score data: ${missingLabels.join(', ')}'
        : result.explanation;
    return Card(
      child: Column(
        children: [
          ListTile(
            key: Key('cars_excluded_${result.destinationId}'),
            leading: const Icon(Icons.info_outline),
            title: Text(result.destinationName),
            subtitle: Text(limitation),
          ),
          _buildAssessmentEvidence(result.destinationId),
        ],
      ),
    );
  }

  Widget _buildAssessmentEvidence(String destinationId) {
    final prepared = widget.assessmentInputs[destinationId];
    if (prepared == null) return const SizedBox.shrink();
    return ExpansionTile(
      key: Key('cars_evidence_$destinationId'),
      title: const Text('Criterion evidence and availability'),
      children: [
        for (final criterion in CarsCriterion.values)
          _buildCriterionEvidence(criterion, prepared.criteria[criterion]),
      ],
    );
  }

  Widget _buildCriterionEvidence(
    CarsCriterion criterion,
    CarsPreparedCriterionInput? input,
  ) {
    final label = _criterionLabels[criterion] ?? criterion.name;
    if (input == null) {
      return ListTile(
        dense: true,
        title: Text(label),
        subtitle: const Text('Evidence details were not supplied.'),
      );
    }
    final details = _provenanceDetails(
      input.evidence,
      ratingIsAvailable:
          input.inputStatus == CarsAssessmentInputStatus.available,
    );
    return ListTile(
      dense: true,
      title: Text('$label · ${_readable(input.inputStatus.name)}'),
      subtitle: Text(
        [
          input.explanation,
          'Score preparation: ${_readable(input.scoreStatus.name)}.',
          if (input.approvedRuleReference != null)
            'Scoring rule: ${input.approvedRuleReference}',
          if (input.criterionScore == null)
            'No numeric criterion score was supplied.',
          ...details,
        ].join(' '),
      ),
    );
  }

  List<String> _provenanceDetails(
    Object? evidence, {
    bool ratingIsAvailable = false,
  }) {
    if (evidence is DestinationRecord) {
      return [
        if (ratingIsAvailable && evidence.rating != null)
          'Verified rating evidence: ${evidence.rating}/5 (not a CARS score).',
        if (evidence.ratingSource != null) 'Source: ${evidence.ratingSource}',
        if (evidence.ratingRetrievedAt != null)
          'Retrieved: ${_dateTimeLabel(evidence.ratingRetrievedAt!)}',
        if (evidence.ratingFreshUntil != null)
          'Fresh until: ${_dateTimeLabel(evidence.ratingFreshUntil!)}',
      ];
    }
    if (evidence is WeatherForecastResult) {
      return [
        'Source: OpenWeatherMap forecast',
        'Forecast period: '
            '${_dateLabel(evidence.requestedStartDate)} to '
            '${_dateLabel(evidence.requestedEndDate)}',
        'Retrieved: ${_dateTimeLabel(evidence.retrievedAt)}',
        'Coverage: ${_readable(evidence.coverage.name)}',
      ];
    }
    if (evidence is CarsTravelAssessment) {
      final legs = evidence.days.expand((day) => day.legs);
      final sources = legs
          .map((leg) => leg.source)
          .whereType<String>()
          .where((source) => source.trim().isNotEmpty)
          .toSet();
      final retrievals = legs
          .map((leg) => leg.retrievedAt)
          .whereType<DateTime>()
          .toSet();
      return [
        if (sources.isNotEmpty) 'Route source: ${sources.join(', ')}',
        if (retrievals.isNotEmpty)
          'Retrieved: ${retrievals.map(_dateTimeLabel).join(', ')}',
        ...evidence.limitations,
      ];
    }
    if (evidence is CarsBudgetAssessment) {
      return [
        if (evidence.currency != null) 'Currency: ${evidence.currency}',
        if (evidence.missingInformation.isNotEmpty)
          'Unavailable details: ${evidence.missingInformation.join('; ')}',
      ];
    }
    if (evidence is CarsInterestActivityMatchAssessment) {
      return [
        if (evidence.mappingSourceReference != null)
          'Mapping source: ${evidence.mappingSourceReference}',
        if (evidence.mappingVersion != null)
          'Mapping version: ${evidence.mappingVersion}',
        if (evidence.activitySourceReference != null)
          'Activity source: ${evidence.activitySourceReference}',
        if (evidence.activityRetrievedAt != null)
          'Activities retrieved: '
              '${_dateTimeLabel(evidence.activityRetrievedAt!)}',
        if (evidence.activityFreshUntil != null)
          'Activity evidence valid until: '
              '${_dateTimeLabel(evidence.activityFreshUntil!)}',
        if (evidence.matchedActivityIdentifiers.isNotEmpty)
          'Matched activity identifiers: '
              '${evidence.matchedActivityIdentifiers.join(', ')}',
      ];
    }
    return const [];
  }
}

String _dateLabel(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _dateTimeLabel(DateTime date) => date.toUtc().toIso8601String();

String _readable(String value) => value
    .replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]}',
    )
    .replaceAll('_', ' ');
