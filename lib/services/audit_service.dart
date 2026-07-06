import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/audit_log_record.dart';
import '../models/app_role.dart';

class AuditService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> log(String action, String description, {String? targetId}) async {
    try {
      final user = _client.auth.currentUser;
      String? role;
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        role = profile?['role'] as String?;
      }

      await _client.from('audit_logs').insert({
        'user_id': user?.id,
        'actor_id': user?.id,
        'role': role ?? AppRole.tourist.value,
        'action': action,
        'action_type': action,
        'description': description,
        'target_id': targetId,
      });
    } catch (_) {
      // Non-blocking
    }
  }

  static Future<List<AuditLogRecord>> fetchLogs({int limit = 50}) async {
    final data = await _client
        .from('audit_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    // Enrich with profile email where possible
    final logs = (data as List)
        .map((row) => AuditLogRecord.fromJson(row as Map<String, dynamic>))
        .toList();

    return logs;
  }
}
