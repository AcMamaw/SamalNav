import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/establishment.dart';
import '../models/establishment_overview_stats.dart';
import '../models/payment_record.dart';
import '../models/reservation_record.dart';
import '../models/review_record.dart';
import 'audit_service.dart';

class EstablishmentService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<Establishment?> getMyEstablishment() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('establishments')
        .select()
        .eq('owner_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Establishment.fromJson(data);
  }

  static Future<EstablishmentOverviewStats> getOverviewStats(String establishmentId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final reservations = await _client
        .from('reservations')
        .select('id, reservation_status, eta')
        .eq('establishment_id', establishmentId);

    final payments = await _client
        .from('payments')
        .select('amount, status')
        .eq('establishment_id', establishmentId);

    int todayVisitors = 0;
    int activeBookings = 0;
    double pendingPayments = 0;

    for (final row in reservations as List) {
      final status = row['reservation_status'] as String;
      final eta = DateTime.parse(row['eta'] as String);
      if (eta.isAfter(todayStart) && eta.isBefore(todayEnd) && status == 'confirmed') {
        todayVisitors++;
      }
      if (status == 'confirmed' || status == 'pending') activeBookings++;
    }

    for (final row in payments as List) {
      if (row['status'] == 'pending') {
        pendingPayments += (row['amount'] as num).toDouble();
      }
    }

    return EstablishmentOverviewStats(
      todayVisitors: todayVisitors,
      activeBookings: activeBookings,
      pendingPayments: pendingPayments,
    );
  }

  static Future<List<ReservationRecord>> getArrivalAlerts(String establishmentId) async {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    final data = await _client
        .from('reservations')
        .select('*, profiles(display_name)')
        .eq('establishment_id', establishmentId)
        .eq('reservation_status', 'confirmed')
        .gte('eta', now.toIso8601String())
        .lt('eta', todayEnd.toIso8601String())
        .order('eta');

    return (data as List)
        .map((row) => ReservationRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ReservationRecord>> getReservations(String establishmentId) async {
    final data = await _client
        .from('reservations')
        .select('*, profiles(display_name)')
        .eq('establishment_id', establishmentId)
        .order('eta', ascending: false);

    return (data as List)
        .map((row) => ReservationRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateReservationStatus(String reservationId, String status) async {
    await _client
        .from('reservations')
        .update({'reservation_status': status})
        .eq('id', reservationId);
    await AuditService.log('RESERVATION', 'Updated reservation $reservationId to $status');
  }

  static Future<List<PaymentRecord>> getPayments(String establishmentId) async {
    final data = await _client
        .from('payments')
        .select('*, profiles(display_name)')
        .eq('establishment_id', establishmentId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => PaymentRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markPaymentPaid(String paymentId) async {
    await _client.from('payments').update({
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);
    await AuditService.log('PAYMENT', 'Marked payment $paymentId as paid');
  }

  static Future<List<ReviewRecord>> getReviews(String establishmentId) async {
    final data = await _client
        .from('reviews')
        .select('*, profiles(display_name)')
        .eq('establishment_id', establishmentId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => ReviewRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<double> getAverageRating(String establishmentId) async {
    final data = await _client
        .from('reviews')
        .select('stars')
        .eq('establishment_id', establishmentId);

    final list = data as List;
    if (list.isEmpty) return 0;
    final total = list.fold<int>(0, (sum, r) => sum + (r['stars'] as int));
    return total / list.length;
  }
}
