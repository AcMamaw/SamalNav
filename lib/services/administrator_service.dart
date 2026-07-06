import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/destination_record.dart';
import '../models/location_verification.dart';
import 'audit_service.dart';

class AdministratorService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<DestinationRecord>> getDestinations() async {
    final data = await _client.from('destinations').select().order('name');

    return (data as List)
        .map((row) => DestinationRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> setDestinationActive(String id, bool isActive) async {
    final status = isActive ? 'active' : 'inactive';
    await _client.from('destinations').update({
      'status': status,
      'is_active': isActive,
    }).eq('id', id);
    await AuditService.log(
      'UPDATE',
      '${isActive ? 'Activated' : 'Deactivated'} destination $id',
      targetId: id,
    );
  }

  static Future<List<LocationVerification>> getPendingVerifications() async {
    final data = await _client
        .from('location_verifications')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => LocationVerification.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> approveVerification(LocationVerification item) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('location_verifications').update({
      'status': 'approved',
      'reviewed_by': userId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', item.id);

    final inserted = await _client.from('destinations').insert({
      'name': item.name,
      'location': item.address,
      'description': 'Verified destination in Samal Island.',
      'lat': item.lat,
      'lng': item.lng,
      'category': item.category,
      'status': 'active',
      'is_active': true,
      'is_verified': true,
    }).select('id').single();

    await AuditService.log('VERIFY', 'Verified location: ${item.name}', targetId: inserted['id'] as String);
  }

  static Future<void> rejectVerification(LocationVerification item) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('location_verifications').update({
      'status': 'rejected',
      'reviewed_by': userId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', item.id);

    await AuditService.log('VERIFY', 'Rejected location: ${item.name}', targetId: item.id);
  }

  static Future<Map<String, int>> getReportStats() async {
    final destinations = await _client.from('destinations').select('status, is_active, is_verified');
    final establishments = await _client.from('establishments').select('is_verified');
    final pending = await _client.from('location_verifications').select('id').eq('status', 'pending');
    final reservations = await _client.from('reservations').select('id');
    final events = await _client.from('events').select('id');

    int activeDest = 0;
    int inactiveDest = 0;
    for (final d in destinations as List) {
      final active = d['status'] == 'active' || d['is_active'] == true;
      if (active) {
        activeDest++;
      } else {
        inactiveDest++;
      }
    }

    int verifiedEst = 0;
    for (final e in establishments as List) {
      if (e['is_verified'] == true) verifiedEst++;
    }

    return {
      'totalVisits': (reservations as List).length,
      'verifiedEstablishments': verifiedEst,
      'pendingVerifications': (pending as List).length,
      'inactiveDestinations': inactiveDest,
      'activeDestinations': activeDest,
      'totalEvents': (events as List).length,
    };
  }

  static Future<List<Map<String, dynamic>>> getEvents() async {
    final data = await _client
        .from('events')
        .select('*, profiles(display_name)')
        .order('event_date', ascending: true);
    return (data as List).cast<Map<String, dynamic>>();
  }
}
