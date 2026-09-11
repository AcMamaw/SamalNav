import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/routes.dart';
import '../models/app_role.dart';

class RoleService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Home route for each role after login.
  static String homeRouteFor(AppRole role) {
    switch (role) {
      case AppRole.tourist:
        return AppRoutes.home;
      case AppRole.establishmentOwner:
        return AppRoutes.establishmentOwner;
      case AppRole.administrator:
        return AppRoutes.administrator;
      case AppRole.superAdmin:
        return AppRoutes.superAdmin;
    }
  }

  /// Fetch the signed-in user's role from the profiles table.
  static Future<AppRole> fetchCurrentUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return AppRole.tourist;

    try {
      final data = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && data['role'] != null) {
        return AppRole.fromString(data['role'] as String?);
      }

      // Fallback: auth user metadata (useful during onboarding)
      final metaRole = user.userMetadata?['role'] as String?;
      if (metaRole != null) {
        return AppRole.fromString(metaRole);
      }
    } catch (_) {
      // profiles.role column may not exist yet — default to tourist
    }

    return AppRole.tourist;
  }

  /// Create or update a profile row for a newly registered tourist.
  static Future<void> ensureTouristProfile({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'email': email,
      'display_name': displayName,
      'role': AppRole.tourist.value,
    });
  }

  /// Redirect if the current user does not have one of [allowedRoles].
  static Future<void> guardRoute(
    BuildContext context, {
    required List<AppRole> allowedRoles,
  }) async {
    final role = await fetchCurrentUserRole();
    if (!allowedRoles.contains(role) && context.mounted) {
      Navigator.of(context).pushReplacementNamed(homeRouteFor(role));
    }
  }

  static Future<void> signOutAndGoLanding(BuildContext context) async {
    await _client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.landing,
        (route) => false,
      );
    }
  }
}
