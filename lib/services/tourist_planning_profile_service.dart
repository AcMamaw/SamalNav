import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tourist_planning_profile.dart';

/// Authenticated-user access to `public.tourist_details`.
///
/// This service never accepts an owner ID from a caller. The active Supabase
/// session supplies `user_id`; deployed grants and RLS must permit the request.
class TouristPlanningProfileService {
  static const String _table = 'tourist_details';

  final SupabaseClient _client;

  TouristPlanningProfileService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Returns null when the signed-in user's row does not exist.
  ///
  /// Since the deployed contract has no confirmation field, every loaded
  /// profile is explicitly reported as unconfirmed for recommendation use.
  Future<TouristPlanningProfileSnapshot?> fetchCurrent() async {
    final userId = _requireCurrentUserId();
    final row = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return TouristPlanningProfileSnapshot(
      profile: TouristPlanningProfile.fromJson(row),
      preferencesConfirmed: false,
    );
  }

  /// Creates a row using database defaults only when no row exists.
  ///
  /// Defaults remain unconfirmed. The insert omits preference columns so the
  /// database, rather than client assumptions, supplies its configured values.
  Future<TouristPlanningProfileSnapshot> createIfMissing() async {
    final existing = await fetchCurrent();
    if (existing != null) return existing;

    final userId = _requireCurrentUserId();
    try {
      final row = await _client
          .from(_table)
          .insert({'user_id': userId})
          .select()
          .single();
      return TouristPlanningProfileSnapshot(
        profile: TouristPlanningProfile.fromJson(row),
        preferencesConfirmed: false,
      );
    } on PostgrestException catch (error) {
      // Concurrent first-time requests can race on the unique user_id key.
      if (error.code == '23505') {
        final raced = await fetchCurrent();
        if (raced != null) return raced;
      }
      rethrow;
    }
  }

  /// Validates and updates only the current user's planning fields.
  Future<TouristPlanningProfileSnapshot> updateCurrent(
    TouristPlanningProfile profile, {
    required TouristPlanningProfileValidationPolicy policy,
  }) async {
    final userId = _requireCurrentUserId();
    if (profile.userId != userId) {
      throw const TouristPlanningProfileServiceException(
        'The profile does not belong to the authenticated user.',
      );
    }
    final validation = profile.validate(policy);
    if (!validation.isValid) {
      throw TouristPlanningProfileValidationException(validation.errors);
    }

    final row = await _client
        .from(_table)
        .update(profile.toJson())
        .eq('user_id', userId)
        .select()
        .maybeSingle();
    if (row == null) {
      throw const TouristPlanningProfileServiceException(
        'No accessible planning profile exists for the authenticated user.',
      );
    }
    return TouristPlanningProfileSnapshot(
      profile: TouristPlanningProfile.fromJson(row),
      // No deployed confirmation field exists yet; never infer confirmation
      // from the persisted values, including values explicitly just edited.
      preferencesConfirmed: false,
    );
  }

  String _requireCurrentUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const TouristPlanningProfileAuthenticationException(
        'Sign in before accessing planning preferences.',
      );
    }
    return user.id;
  }
}

class TouristPlanningProfileSnapshot {
  final TouristPlanningProfile profile;
  final bool preferencesConfirmed;

  const TouristPlanningProfileSnapshot({
    required this.profile,
    required this.preferencesConfirmed,
  });
}

class TouristPlanningProfileServiceException implements Exception {
  final String message;

  const TouristPlanningProfileServiceException(this.message);

  @override
  String toString() => message;
}

class TouristPlanningProfileAuthenticationException
    extends TouristPlanningProfileServiceException {
  const TouristPlanningProfileAuthenticationException(super.message);
}

class TouristPlanningProfileValidationException
    extends TouristPlanningProfileServiceException {
  final Map<String, String> errors;

  TouristPlanningProfileValidationException(this.errors)
    : super('Planning profile validation failed: ${errors.keys.join(', ')}.');
}
