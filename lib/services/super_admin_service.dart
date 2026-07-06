import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_role.dart';
import '../models/audit_log_record.dart';
import '../models/user_profile_record.dart';
import 'audit_service.dart';

class SuperAdminService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<Map<String, int>> getUserStatsByRole() async {
    final data = await _client.from('profiles').select('role');
    final counts = <String, int>{
      'tourist': 0,
      'establishment': 0,
      'administrator': 0,
      'super_admin': 0,
    };

    for (final row in data as List) {
      final role = row['role'] as String? ?? 'tourist';
      counts[role] = (counts[role] ?? 0) + 1;
    }

    return counts;
  }

  static Future<List<AuditLogRecord>> getRecentActivity({int limit = 20}) async {
    return AuditService.fetchLogs(limit: limit);
  }

  static Future<List<AuditLogRecord>> getAuditLogs({int limit = 100}) async {
    return AuditService.fetchLogs(limit: limit);
  }

  static Future<List<UserProfileRecord>> getAllUsers() async {
    final data = await _client
        .from('profiles')
        .select('id, email, display_name, role')
        .order('display_name');

    return (data as List)
        .map((row) => UserProfileRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateUserRole(String userId, AppRole role) async {
    await _client.from('profiles').update({'role': role.value}).eq('id', userId);
    await AuditService.log('ROLE', 'Assigned role ${role.value} to user $userId');
  }

  static Future<bool> getMaintenanceMode() async {
    final data = await _client
        .from('system_settings')
        .select('value')
        .eq('key', 'maintenance_mode')
        .maybeSingle();

    if (data == null) return false;
    final value = data['value'] as Map<String, dynamic>?;
    return value?['enabled'] as bool? ?? false;
  }

  static Future<void> setMaintenanceMode(bool enabled) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('system_settings').upsert({
      'key': 'maintenance_mode',
      'value': {'enabled': enabled},
      'updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await AuditService.log(
      'MAINT',
      enabled ? 'Maintenance mode enabled' : 'Maintenance mode disabled',
    );
  }

  static Future<int> getActionsTodayCount() async {
    final today = DateTime.now();
    final start =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final data = await _client
        .from('audit_logs')
        .select('id')
        .gte('created_at', start);

    return (data as List).length;
  }
}
