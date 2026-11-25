import 'package:flutter/material.dart';

import '../../models/itinerary_draft.dart';
import '../../services/cars_recommendation_provider.dart';
import '../../services/tourist_planning_profile_service.dart';
import '../../services/tourist_planning_profile_trip_adapter.dart';
import 'cars_recommendation_review_page.dart';
import 'planning_preferences_page.dart';

/// Application entry boundary for system-generated planning.
///
/// The default provider is intentionally unavailable until real, verified CARS
/// inputs and approved scoring configuration are connected.
class SystemGeneratedPlanningPage extends StatefulWidget {
  final TripConfiguration trip;
  final CarsRecommendationProvider provider;
  final TouristPlanningProfileService? profileService;

  const SystemGeneratedPlanningPage({
    super.key,
    required this.trip,
    this.provider = const UnavailableCarsRecommendationProvider(),
    this.profileService,
  });

  @override
  State<SystemGeneratedPlanningPage> createState() =>
      _SystemGeneratedPlanningPageState();
}

class _SystemGeneratedPlanningPageState
    extends State<SystemGeneratedPlanningPage> {
  TouristPlanningProfileSnapshot? _profileSnapshot;
  bool _profileLoading = true;
  String? _profileError;
  bool _loading = false;
  String? _error;
  bool _empty = false;
  bool _hasStartedRecommendations = false;
  TripConfiguration? _recommendationTrip;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  TouristPlanningProfileService get _profileService =>
      widget.profileService ?? TouristPlanningProfileService();

  Future<void> _loadProfile() async {
    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    try {
      final snapshot = await _profileService.fetchCurrent();
      if (!mounted) return;
      setState(() {
        _profileSnapshot = snapshot;
        _profileLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _profileLoading = false;
        _profileError = error.toString();
      });
    }
  }

  Future<void> _reviewPreferences() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PlanningPreferencesPage(service: _profileService),
      ),
    );
    if (mounted) await _loadProfile();
  }

  Future<void> _loadRecommendations({bool useConfirmedProfile = true}) async {
    final snapshot = _profileSnapshot;
    final trip = useConfirmedProfile && snapshot != null
        ? const TouristPlanningProfileTripAdapter().applyConfirmedDefaults(
            snapshot: snapshot,
            currentTrip: widget.trip,
          )
        : widget.trip;
    setState(() {
      _loading = true;
      _error = null;
      _empty = false;
      _hasStartedRecommendations = true;
      _recommendationTrip = trip;
    });
    try {
      final package = await widget.provider.recommend(trip);
      if (!mounted) return;
      if (package.ranking.ranked.isEmpty && package.ranking.excluded.isEmpty) {
        setState(() {
          _loading = false;
          _empty = true;
        });
        return;
      }

      final reviewed = await Navigator.of(context).push<ItineraryDraft>(
        MaterialPageRoute(
          builder: (_) => CarsRecommendationReviewPage(
            ranking: package.ranking,
            destinations: package.destinations,
            assessmentInputs: package.assessmentInputs,
            trip: trip,
            carsRunReference: package.runReference,
          ),
        ),
      );
      if (!mounted) return;
      if (reviewed != null) {
        Navigator.of(context).pop(reviewed);
      } else {
        setState(() => _loading = false);
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('System-generated planning')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _TripSummary(trip: _recommendationTrip ?? widget.trip),
          const SizedBox(height: 16),
          _profileCard(),
          const SizedBox(height: 16),
          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Checking available CARS recommendation data…'),
                  ],
                ),
              ),
            )
          else if (!_hasStartedRecommendations)
            FilledButton.icon(
              key: const Key('generate_cars_recommendations'),
              onPressed: _profileLoading
                  ? null
                  : () => _loadRecommendations(
                      useConfirmedProfile: _profileError == null,
                    ),
              icon: const Icon(Icons.travel_explore),
              label: Text(
                _profileError == null
                    ? 'Generate recommendations'
                    : 'Continue with current trip settings',
              ),
            )
          else if (_error != null)
            Card(
              key: const Key('cars_provider_unavailable'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommendations unavailable',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(_error!),
                    const SizedBox(height: 12),
                    const Text(
                      'The destination directory may contain ratings, raw '
                      'prices, and coordinates, but the app has no verified '
                      'activity-match or weather provider, no trusted rating '
                      'freshness contract, and no approved mapping from '
                      'inputs to all six normalized CARS scores and weights. '
                      'The bundled offline destination list is not used as '
                      'a recommendation source.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('retry_cars_recommendations'),
                      onPressed: () => _loadRecommendations(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          else if (_empty)
            Card(
              key: const Key('cars_provider_empty'),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('No recommendation results are available.'),
                    subtitle: Text(
                      'No destinations were ranked or excluded. Try again when '
                      'the CARS data provider is available.',
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('retry_cars_empty'),
                    onPressed: () => _loadRecommendations(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Recommendation review closed'),
                    subtitle: Text(
                      'You can retry to reopen the recommendation review.',
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('retry_cars_closed'),
                    onPressed: () => _loadRecommendations(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  Widget _profileCard() {
    if (_profileLoading) {
      return const Card(
        key: Key('planning_profile_loading'),
        child: ListTile(
          leading: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Loading saved planning preferences'),
        ),
      );
    }
    final error = _profileError;
    if (error != null) {
      return Card(
        key: const Key('planning_profile_load_error'),
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: const Text('Saved preferences could not be loaded'),
          subtitle: Text(
            '$error\nYour current trip settings will be kept. No saved values '
            'will be substituted.',
          ),
          isThreeLine: true,
          trailing: IconButton(
            key: const Key('retry_planning_profile_load'),
            tooltip: 'Retry loading preferences',
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
          ),
        ),
      );
    }

    final snapshot = _profileSnapshot;
    if (snapshot == null) {
      return const Card(
        key: Key('planning_profile_missing'),
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('No saved planning profile'),
          subtitle: Text(
            'This is not an incomplete category preference. Your current trip '
            'settings remain in use.',
          ),
        ),
      );
    }

    final categories = snapshot.profile.preferredCategories;
    final selection = categories == null || categories.isEmpty
        ? 'No category preference selected.'
        : 'Saved category identifiers are unverified and will not be sent to CARS.';
    final confirmed = snapshot.preferencesConfirmed;
    return Card(
      key: const Key('planning_profile_status'),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              confirmed ? Icons.verified_outlined : Icons.info_outline,
            ),
            title: Text(
              confirmed
                  ? 'Saved preferences are confirmed'
                  : 'Saved preferences are unconfirmed',
            ),
            subtitle: Text(
              '$selection\n'
              '${confirmed ? 'Supported missing trip fields may use these values.' : 'Saved profile values will not be applied to CARS.'} '
              'The current trip configuration is preserved.',
            ),
            isThreeLine: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('review_saved_planning_preferences'),
              onPressed: _profileLoading ? null : _reviewPreferences,
              icon: const Icon(Icons.tune),
              label: const Text('Review or edit preferences'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripSummary extends StatelessWidget {
  final TripConfiguration trip;

  const _TripSummary({required this.trip});

  @override
  Widget build(BuildContext context) {
    final origin = trip.origin;
    final date = trip.startDate;
    return Card(
      key: const Key('system_generated_trip_context'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip context passed to the recommendation provider',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${trip.durationDays} day(s), ${trip.availableHoursPerDay} hours per day',
            ),
            if (date != null)
              Text(
                'Start date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              ),
            if (trip.budgetMinimum != null || trip.budgetMaximum != null)
              Text(
                'Budget: ${trip.budgetMinimum ?? 'unspecified'}–${trip.budgetMaximum ?? 'unspecified'} ${trip.currency ?? ''} (${trip.budgetBasis?.name ?? 'basis unspecified'})',
              ),
            if (trip.totalGroupSize != null)
              Text(
                'Group size: ${trip.totalGroupSize}; children: ${trip.childrenCount ?? 'unspecified'}; elders: ${trip.eldersCount ?? 'unspecified'}',
              ),
            if (origin != null)
              Text(
                'Tourist-selected origin: ${origin.label ?? '${origin.latitude}, ${origin.longitude}'}',
              ),
            if (trip.travelMode != null)
              Text('Travel mode: ${trip.travelMode!.value}'),
            if (trip.requiredTransfers.isNotEmpty)
              Text('Required transfers: ${trip.requiredTransfers.length}'),
          ],
        ),
      ),
    );
  }
}
