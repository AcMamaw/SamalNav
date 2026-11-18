import 'package:flutter/material.dart';

import '../../models/tourist_planning_profile.dart';
import '../../services/tourist_planning_profile_service.dart';
import '../../theme/palette.dart';

class PlanningPreferencesPage extends StatefulWidget {
  PlanningPreferencesPage({super.key, TouristPlanningProfileService? service})
    : service = service ?? TouristPlanningProfileService();

  final TouristPlanningProfileService service;

  @override
  State<PlanningPreferencesPage> createState() =>
      _PlanningPreferencesPageState();
}

class _PlanningPreferencesPageState extends State<PlanningPreferencesPage> {
  static const _travelModes = <String>[
    'walking',
    'bicycle',
    'motorcycle',
    'car',
    'public transportation',
  ];

  final _formKey = GlobalKey<FormState>();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _hoursController = TextEditingController();
  final _daysController = TextEditingController();
  final _groupSizeController = TextEditingController();
  final _childrenController = TextEditingController();
  final _eldersController = TextEditingController();

  TouristPlanningProfileSnapshot? _snapshot;
  String? _selectedTravelMode;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _hoursController.dispose();
    _daysController.dispose();
    _groupSizeController.dispose();
    _childrenController.dispose();
    _eldersController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final snapshot =
          await widget.service.fetchCurrent() ??
          await widget.service.createIfMissing();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _setControllers(snapshot.profile);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _errorMessage(error);
        _loading = false;
      });
    }
  }

  void _setControllers(TouristPlanningProfile profile) {
    _budgetMinController.text = profile.budgetMin.toString();
    _budgetMaxController.text = profile.budgetMax.toString();
    _hoursController.text = profile.availableHoursPerDay.toString();
    _daysController.text = profile.tripDurationDays.toString();
    _groupSizeController.text = profile.numberOfTourists?.toString() ?? '';
    _childrenController.text = profile.childrenCount?.toString() ?? '';
    _eldersController.text = profile.eldersCount?.toString() ?? '';
    _selectedTravelMode = profile.travelMode;
  }

  int? get _derivedAdults {
    final total = int.tryParse(_groupSizeController.text);
    if (total == null) return null;
    if (_childrenController.text.trim().isEmpty ||
        _eldersController.text.trim().isEmpty) {
      return null;
    }
    final children = int.tryParse(_childrenController.text.trim());
    final elders = int.tryParse(_eldersController.text.trim());
    if (children == null || elders == null) return null;
    final adults = total - children - elders;
    return adults < 0 ? null : adults;
  }

  Future<void> _reviewAndSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final current = _snapshot?.profile;
    if (current == null) return;
    final candidate = TouristPlanningProfile(
      id: current.id,
      userId: current.userId,
      budgetMin: double.parse(_budgetMinController.text.trim()),
      budgetMax: double.parse(_budgetMaxController.text.trim()),
      availableHoursPerDay: int.parse(_hoursController.text.trim()),
      tripDurationDays: int.parse(_daysController.text.trim()),
      // Category selection stays disabled until deployed UUID/name mappings
      // are available. Preserve the existing nullable value unchanged.
      preferredCategories: current.preferredCategories,
      // Keep the persisted coordinates as-is. This form does not access GPS
      // and current_lat/current_lng are not treated as a saved trip origin.
      currentLat: current.currentLat,
      currentLng: current.currentLng,
      travelMode: _selectedTravelMode ?? current.travelMode,
      createdAt: current.createdAt,
      numberOfTourists: _parseOptionalInt(_groupSizeController.text),
      childrenCount: _parseOptionalInt(_childrenController.text),
      eldersCount: _parseOptionalInt(_eldersController.text),
    );

    final oldCategories = current.preferredCategories?.toSet() ?? <String>{};
    final allowedModes = {..._travelModes, current.travelMode};
    final policy = TouristPlanningProfileValidationPolicy(
      maximumHoursPerDay: 24,
      maximumTripDays: 30,
      // Existing unverified values are allow-listed only for preservation;
      // this screen offers no category edits until IDs are verified.
      validCategoryCodes: oldCategories,
      supportedTravelModes: allowedModes,
    );
    final validation = candidate.validate(policy);
    if (!validation.isValid) {
      setState(() => _saveError = validation.errors.values.join(' '));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review planning preferences'),
        content: Text(
          'Budget amount: ${candidate.budgetMin} to ${candidate.budgetMax}\n'
          'Schedule: ${candidate.availableHoursPerDay} hours/day for '
          '${candidate.tripDurationDays} day(s)\n'
          'Travel mode: ${candidate.travelMode}\n'
          'Group: ${candidate.numberOfTourists?.toString() ?? 'not set'} '
          'total; ${_derivedAdults?.toString() ?? 'adults not derivable'} adults\n\n'
          'Budget basis, category selection, and separate trip origin are not '
          'available in the current schema/reference data. The database also '
          'cannot persist a confirmation timestamp, so this profile will '
          'remain unconfirmed after saving.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            key: const Key('confirm_save_preferences'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm and save'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final updated = await widget.service.updateCurrent(
        candidate,
        policy: policy,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = updated;
        _setControllers(updated.profile);
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved. Profile remains unconfirmed.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = _errorMessage(error);
        _saving = false;
      });
    }
  }

  int? _parseOptionalInt(String text) =>
      text.trim().isEmpty ? null : int.tryParse(text.trim());

  String _errorMessage(Object error) {
    if (error is TouristPlanningProfileAuthenticationException) {
      return error.message;
    }
    if (error is TouristPlanningProfileValidationException) {
      return error.errors.values.join(' ');
    }
    return 'Could not load or save planning preferences. Please try again.';
  }

  String? _validateNumber(
    String? value, {
    required String label,
    required bool integer,
    num? minimum,
    num? maximum,
  }) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return '$label is required.';
    final parsed = integer ? int.tryParse(input) : double.tryParse(input);
    if (parsed == null || (parsed is double && !parsed.isFinite)) {
      return 'Enter a valid $label.';
    }
    if (minimum != null && parsed < minimum) {
      return '$label must be at least $minimum.';
    }
    if (maximum != null && parsed > maximum) {
      return '$label must be at most $maximum.';
    }
    return null;
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required String keyName,
    required bool integer,
    required bool requiredValue,
    num? minimum,
    num? maximum,
    String? helperText,
    bool refreshOnChange = false,
  }) {
    return TextFormField(
      key: Key(keyName),
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      decoration: InputDecoration(labelText: label, helperText: helperText),
      validator: requiredValue
          ? (value) => _validateNumber(
              value,
              label: label,
              integer: integer,
              minimum: minimum,
              maximum: maximum,
            )
          : (value) {
              if ((value ?? '').trim().isEmpty) return null;
              return _validateNumber(
                value,
                label: label,
                integer: true,
                minimum: minimum,
              );
            },
      onChanged: refreshOnChange ? (_) => setState(() {}) : null,
    );
  }

  Widget _notice({required IconData icon, required String text}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppPalette.iceBlue,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppPalette.blue, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Planning preferences')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _snapshot!.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Planning preferences')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Card(
                color: Colors.amber.shade50,
                child: const ListTile(
                  key: Key('unconfirmed_profile_notice'),
                  leading: Icon(Icons.info_outline),
                  title: Text('Preferences are unconfirmed'),
                  subtitle: Text(
                    'Saved values and database defaults are not confirmation. '
                    'Persistent confirmation is unavailable in the current schema.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Budget amounts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Enter amounts without a currency assumption. The database has no currency or budget-basis field.',
              ),
              _numberField(
                label: 'Minimum budget',
                controller: _budgetMinController,
                keyName: 'budget_min_field',
                integer: false,
                requiredValue: true,
                minimum: 0,
              ),
              _numberField(
                label: 'Maximum budget',
                controller: _budgetMaxController,
                keyName: 'budget_max_field',
                integer: false,
                requiredValue: true,
                minimum: 0,
              ),
              _notice(
                icon: Icons.block_outlined,
                text:
                    'Budget basis (per person or total group) cannot be saved: the deployed profile has no budget-basis column.',
              ),
              const SizedBox(height: 20),
              Text(
                'Trip schedule',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _numberField(
                label: 'Available hours per day',
                controller: _hoursController,
                keyName: 'available_hours_field',
                integer: true,
                requiredValue: true,
                minimum: 1,
                maximum: 24,
              ),
              _numberField(
                label: 'Trip duration (days)',
                controller: _daysController,
                keyName: 'trip_days_field',
                integer: true,
                requiredValue: true,
                minimum: 1,
                maximum: 30,
              ),
              const SizedBox(height: 20),
              Text(
                'Destination interests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _notice(
                icon: Icons.info_outline,
                text:
                    'Category selection is unavailable until the deployed category UUIDs and readable-name mapping are verified. Existing stored values are preserved without being treated as verified.',
              ),
              if (profile.preferredCategories == null)
                const Text('No category value is available in this profile.')
              else if (profile.preferredCategories!.isEmpty)
                const Text('No categories are currently selected.')
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Saved category identifiers (unverified): ${profile.preferredCategories!.join(', ')}',
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Trip starting point',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _notice(
                icon: Icons.location_off_outlined,
                text:
                    'A separate trip-origin field is not available in the deployed profile schema. Current-location coordinates are not used or overwritten here.',
              ),
              const SizedBox(height: 20),
              Text(
                'Travel mode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              DropdownButtonFormField<String>(
                key: const Key('travel_mode_dropdown'),
                initialValue: _selectedTravelMode,
                decoration: const InputDecoration(
                  labelText: 'Preferred travel mode',
                ),
                items: [
                  if (!_travelModes.contains(_selectedTravelMode))
                    DropdownMenuItem(
                      value: _selectedTravelMode,
                      child: Text(
                        'Saved value: $_selectedTravelMode (unsupported)',
                      ),
                    ),
                  ..._travelModes.map(
                    (mode) => DropdownMenuItem(value: mode, child: Text(mode)),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _selectedTravelMode = value),
              ),
              const SizedBox(height: 20),
              Text(
                'Travel group',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _numberField(
                label: 'Total group size',
                controller: _groupSizeController,
                keyName: 'group_size_field',
                integer: true,
                requiredValue: false,
                minimum: 1,
                refreshOnChange: true,
              ),
              _numberField(
                label: 'Children count',
                controller: _childrenController,
                keyName: 'children_count_field',
                integer: true,
                requiredValue: false,
                minimum: 0,
                refreshOnChange: true,
              ),
              _numberField(
                label: 'Elders count',
                controller: _eldersController,
                keyName: 'elders_count_field',
                integer: true,
                requiredValue: false,
                minimum: 0,
                refreshOnChange: true,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Adults (derived): ${_derivedAdults?.toString() ?? '—'}',
                  key: const Key('derived_adults'),
                ),
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _saveError!,
                  key: const Key('save_error'),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('review_save_preferences'),
                onPressed: _saving ? null : _reviewAndSave,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_outlined),
                label: Text(
                  _saving ? 'Saving…' : 'Review and save preferences',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
