import '../models/itinerary_draft.dart';
import 'tourist_planning_profile_service.dart';

/// Applies only explicitly confirmed, supported profile values that are
/// missing from the current trip configuration.
///
/// Existing trip inputs always win. Profile budget amounts are not applied
/// because the stored profile has no currency or budget-basis field. Stored
/// coordinates are not a tourist-selected trip origin, and category IDs are
/// not mapped to CARS interests without a verified category catalog.
class TouristPlanningProfileTripAdapter {
  const TouristPlanningProfileTripAdapter();

  TripConfiguration applyConfirmedDefaults({
    required TouristPlanningProfileSnapshot snapshot,
    required TripConfiguration currentTrip,
  }) {
    if (!snapshot.preferencesConfirmed) return currentTrip;

    final profile = snapshot.profile;
    return TripConfiguration(
      startDate: currentTrip.startDate,
      durationDays: currentTrip.durationDays,
      availableHoursPerDay: currentTrip.availableHoursPerDay,
      budgetMinimum: currentTrip.budgetMinimum,
      budgetMaximum: currentTrip.budgetMaximum,
      budgetBasis: currentTrip.budgetBasis,
      currency: currentTrip.currency,
      totalGroupSize: currentTrip.totalGroupSize ?? profile.numberOfTourists,
      childrenCount: currentTrip.childrenCount ?? profile.childrenCount,
      eldersCount: currentTrip.eldersCount ?? profile.eldersCount,
      // current_lat/current_lng are not the user's selected trip origin.
      origin: currentTrip.origin,
      travelMode: currentTrip.travelMode ?? _travelMode(profile.travelMode),
      requiredTransfers: currentTrip.requiredTransfers,
    );
  }

  PreferredTravelMode? _travelMode(String value) => switch (value) {
    'walking' => PreferredTravelMode.walking,
    'bicycle' => PreferredTravelMode.bicycle,
    'motorcycle' => PreferredTravelMode.motorcycle,
    'car' => PreferredTravelMode.car,
    'public transportation' => PreferredTravelMode.publicTransportation,
    _ => null,
  };
}
