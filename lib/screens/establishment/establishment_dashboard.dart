import 'package:flutter/material.dart';
import '../../models/establishment.dart';
import '../../models/establishment_overview_stats.dart';
import '../../models/app_role.dart';
import '../../models/reservation_record.dart';
import '../../models/payment_record.dart';
import '../../models/review_record.dart';
import '../../services/establishment_service.dart';
import '../../services/role_service.dart';
import '../../theme/palette.dart';
import '../../utils/time_utils.dart';
import '../../widgets/role_dashboard_shell.dart';

typedef _P = AppPalette;

class EstablishmentDashboard extends StatefulWidget {
  const EstablishmentDashboard({super.key});

  @override
  State<EstablishmentDashboard> createState() => _EstablishmentDashboardState();
}

class _EstablishmentDashboardState extends State<EstablishmentDashboard> {
  Establishment? _establishment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await RoleService.guardRoute(
        context,
        allowedRoles: const [AppRole.establishment],
      );
      await _loadEstablishment();
    });
  }

  Future<void> _loadEstablishment() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final est = await EstablishmentService.getMyEstablishment();
      if (mounted) setState(() => _establishment = est);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _P.blue)),
      );
    }

    if (_establishment == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        appBar: AppBar(
          backgroundColor: _P.deepNavy,
          foregroundColor: Colors.white,
          title: const Text('Establishment Portal'),
          actions: [
            IconButton(
              onPressed: () => RoleService.signOutAndGoLanding(context),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store_outlined, size: 64, color: _P.inkSoft),
                const SizedBox(height: 16),
                const Text(
                  'No establishment linked',
                  style: TextStyle(
                    color: _P.deepNavy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Ask an administrator to link your account to an establishment in the database.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _P.inkSoft),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadEstablishment,
                  style: ElevatedButton.styleFrom(backgroundColor: _P.blue),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final est = _establishment!;
    return RoleDashboardShell(
      role: AppRole.establishment,
      subtitle: est.name,
      navItems: const [
        RoleNavItem(icon: Icons.dashboard_rounded, label: 'Overview'),
        RoleNavItem(icon: Icons.event_available_rounded, label: 'Bookings'),
        RoleNavItem(icon: Icons.payments_rounded, label: 'Payments'),
        RoleNavItem(icon: Icons.reviews_rounded, label: 'Reviews'),
      ],
      pages: [
        _OverviewTab(establishmentId: est.id),
        _BookingsTab(establishmentId: est.id),
        _PaymentsTab(establishmentId: est.id),
        _ReviewsTab(establishmentId: est.id),
      ],
    );
  }
}

// ── Overview ──────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  final String establishmentId;
  const _OverviewTab({required this.establishmentId});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  EstablishmentOverviewStats? _stats;
  List<ReservationRecord> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await EstablishmentService.getOverviewStats(widget.establishmentId);
      final alerts = await EstablishmentService.getArrivalAlerts(widget.establishmentId);
      if (mounted) {
        setState(() {
          _stats = stats;
          _alerts = alerts;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _P.blue));

    final stats = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      color: _P.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visitor Summary',
                  style: TextStyle(color: _P.deepNavy, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth > 600 ? 3 : 1;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: cols == 1 ? 2.8 : 2.2,
                      children: [
                        DashboardStatCard(
                          title: 'Today\'s Visitors',
                          value: '${stats.todayVisitors}',
                          icon: Icons.people_rounded,
                          accent: _P.blue,
                        ),
                        DashboardStatCard(
                          title: 'Active Bookings',
                          value: '${stats.activeBookings}',
                          icon: Icons.event_available_rounded,
                          accent: const Color(0xFF43A047),
                        ),
                        DashboardStatCard(
                          title: 'Pending Payments',
                          value: '₱${stats.pendingPayments.toStringAsFixed(0)}',
                          icon: Icons.payments_rounded,
                          accent: const Color(0xFFFFA726),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                const DashboardSectionHeader(title: 'Arrival Alerts'),
                const SizedBox(height: 12),
                if (_alerts.isEmpty)
                  const _EmptyState(message: 'No arrival alerts for today.')
                else
                  ..._alerts.map(
                    (b) => _AlertTile(
                      guestName: b.touristName ?? 'Guest',
                      service: b.serviceName ?? 'Reservation',
                      eta: '${b.etaMinutes} min',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final String guestName;
  final String service;
  final String eta;

  const _AlertTile({required this.guestName, required this.service, required this.eta});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.iceBlue),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_active_rounded, color: _P.blue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guestName, style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w700)),
                Text(service, style: const TextStyle(color: _P.inkSoft, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('ETA $eta', style: const TextStyle(color: Color(0xFF388E3C), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Bookings ──────────────────────────────────────────────────────────

class _BookingsTab extends StatefulWidget {
  final String establishmentId;
  const _BookingsTab({required this.establishmentId});

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  List<ReservationRecord> _reservations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await EstablishmentService.getReservations(widget.establishmentId);
      if (mounted) setState(() => _reservations = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) => switch (status) {
        'confirmed' => const Color(0xFF43A047),
        'pending' => const Color(0xFFFFA726),
        'cancelled' => Colors.redAccent,
        _ => _P.inkSoft,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _P.blue));

    return RefreshIndicator(
      onRefresh: _load,
      color: _P.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardSectionHeader(title: 'Manage Tourist Bookings'),
                const SizedBox(height: 16),
                if (_reservations.isEmpty)
                  const _EmptyState(message: 'No reservations yet.')
                else
                  ..._reservations.map((b) {
                    final statusColor = _statusColor(b.reservationStatus);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.04), blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _P.iceBlue,
                            child: Text(
                              (b.touristName ?? 'G')[0],
                              style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.touristName ?? 'Guest', style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w700)),
                                Text('${b.serviceName ?? 'Reservation'} · ${b.paxCount} guest(s)', style: const TextStyle(color: _P.inkSoft, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  b.reservationStatus.toUpperCase(),
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(formatDate(b.eta), style: const TextStyle(color: _P.inkSoft, fontSize: 11)),
                              if (b.reservationStatus == 'pending')
                                TextButton(
                                  onPressed: () async {
                                    await EstablishmentService.updateReservationStatus(b.id, 'confirmed');
                                    _load();
                                  },
                                  child: const Text('Confirm', style: TextStyle(fontSize: 11)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Payments ──────────────────────────────────────────────────────────

class _PaymentsTab extends StatefulWidget {
  final String establishmentId;
  const _PaymentsTab({required this.establishmentId});

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  List<PaymentRecord> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await EstablishmentService.getPayments(widget.establishmentId);
      if (mounted) setState(() => _payments = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _P.blue));

    return RefreshIndicator(
      onRefresh: _load,
      color: _P.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaction Logs & Reservation Fees',
                  style: TextStyle(color: _P.deepNavy, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                const DashboardSectionHeader(title: 'Access Transaction Logs'),
                const SizedBox(height: 12),
                if (_payments.isEmpty)
                  const _EmptyState(message: 'No payments recorded yet.')
                else
                  ..._payments.map((t) {
                    final color = switch (t.status) {
                      'paid' => const Color(0xFF43A047),
                      'pending' => const Color(0xFFFFA726),
                      _ => Colors.redAccent,
                    };
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _P.iceBlue),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: _P.blue),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.touristName ?? 'Guest', style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w700)),
                                Text(t.paymentMethod ?? 'cash', style: const TextStyle(color: _P.inkSoft, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('₱${t.amount.toStringAsFixed(0)}', style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 12),
                          if (t.status == 'pending')
                            TextButton(
                              onPressed: () async {
                                await EstablishmentService.markPaymentPaid(t.id);
                                _load();
                              },
                              child: const Text('Mark Paid'),
                            )
                          else
                            Text(t.status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reviews ───────────────────────────────────────────────────────────

class _ReviewsTab extends StatefulWidget {
  final String establishmentId;
  const _ReviewsTab({required this.establishmentId});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  List<ReviewRecord> _reviews = [];
  double _avgRating = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final reviews = await EstablishmentService.getReviews(widget.establishmentId);
      final avg = await EstablishmentService.getAverageRating(widget.establishmentId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _avgRating = avg;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _P.blue));

    return RefreshIndicator(
      onRefresh: _load,
      color: _P.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Feedback',
                  style: TextStyle(color: _P.deepNavy, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Average Rating',
                        value: _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '—',
                        icon: Icons.star_rounded,
                        accent: const Color(0xFFFFA726),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Total Reviews',
                        value: '${_reviews.length}',
                        icon: Icons.rate_review_rounded,
                        accent: _P.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const DashboardSectionHeader(title: 'Recent Reviews'),
                const SizedBox(height: 12),
                if (_reviews.isEmpty)
                  const _EmptyState(message: 'No reviews yet.')
                else
                  ..._reviews.map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(r.touristName ?? 'Guest', style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w700)),
                                const Spacer(),
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    i < r.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 16,
                                    color: const Color(0xFFFFA726),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(r.reviewText ?? '', style: const TextStyle(color: _P.inkSoft, fontSize: 13, height: 1.4)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.iceBlue),
      ),
      child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _P.inkSoft)),
    );
  }
}
