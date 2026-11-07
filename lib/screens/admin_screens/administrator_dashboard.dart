import 'package:flutter/material.dart';
import '../../models/app_role.dart';
import '../../models/destination_record.dart';
import '../../models/location_verification.dart';
import '../../services/administrator_service.dart';
import '../../services/role_service.dart';
import '../../theme/palette.dart';
import '../../widgets/role_dashboard_shell.dart';

typedef _P = AppPalette;

class AdministratorDashboard extends StatefulWidget {
  const AdministratorDashboard({super.key});

  @override
  State<AdministratorDashboard> createState() => _AdministratorDashboardState();
}

class _AdministratorDashboardState extends State<AdministratorDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleService.guardRoute(
        context,
        allowedRoles: const [AppRole.administrator, AppRole.superAdmin],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleDashboardShell(
      role: AppRole.administrator,
      subtitle: 'Tourism Office Control Panel',
      navItems: const [
        RoleNavItem(icon: Icons.place_rounded, label: 'Destinations'),
        RoleNavItem(icon: Icons.verified_rounded, label: 'Verify Locations'),
        RoleNavItem(icon: Icons.analytics_rounded, label: 'Reports'),
      ],
      pages: const [
        _DestinationsTab(),
        _VerifyLocationsTab(),
        _ReportsTab(),
      ],
    );
  }
}

// ── Destinations ──────────────────────────────────────────────────────

class _DestinationsTab extends StatefulWidget {
  const _DestinationsTab();

  @override
  State<_DestinationsTab> createState() => _DestinationsTabState();
}

class _DestinationsTabState extends State<_DestinationsTab> {
  List<DestinationRecord> _destinations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdministratorService.getDestinations();
      if (mounted) setState(() => _destinations = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(DestinationRecord dest, bool val) async {
    await AdministratorService.setDestinationActive(dest.id, val);
    setState(() {
      _destinations = _destinations.map((d) {
        if (d.id == dest.id) {
          return DestinationRecord(
            id: d.id,
            name: d.name,
            location: d.location,
            lat: d.lat,
            lng: d.lng,
            category: d.category,
            rating: d.rating,
            status: val ? 'active' : 'inactive',
            isVerified: d.isVerified,
            description: d.description,
            rawEntranceFee: d.rawEntranceFee,
            averageStayMinutes: d.averageStayMinutes,
          );
        }
        return d;
      }).toList();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${dest.name} is now ${val ? 'active' : 'inactive'}'),
          backgroundColor: val ? const Color(0xFF43A047) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _P.blue));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final activeCount = _destinations.where((d) => d.isActive).length;

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
                  'Control Active / Inactive Destinations',
                  style: TextStyle(color: _P.deepNavy, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Active',
                        value: '$activeCount',
                        icon: Icons.check_circle_rounded,
                        accent: const Color(0xFF43A047),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Inactive',
                        value: '${_destinations.length - activeCount}',
                        icon: Icons.block_rounded,
                        accent: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const DashboardSectionHeader(title: 'All Destinations'),
                const SizedBox(height: 12),
                ..._destinations.map((dest) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: dest.isActive
                              ? const Color(0xFF43A047).withValues(alpha: 0.3)
                              : Colors.redAccent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            dest.isActive ? Icons.place_rounded : Icons.place_outlined,
                            color: dest.isActive ? _P.blue : _P.inkSoft,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dest.name, style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w700)),
                                Text('${dest.category} · ${dest.location}', style: const TextStyle(color: _P.inkSoft, fontSize: 12)),
                              ],
                            ),
                          ),
                          Switch(
                            value: dest.isActive,
                            activeThumbColor: _P.blue,
                            onChanged: (val) => _toggle(dest, val),
                          ),
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

// ── Verify Locations ──────────────────────────────────────────────────

class _VerifyLocationsTab extends StatefulWidget {
  const _VerifyLocationsTab();

  @override
  State<_VerifyLocationsTab> createState() => _VerifyLocationsTabState();
}

class _VerifyLocationsTabState extends State<_VerifyLocationsTab> {
  List<LocationVerification> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdministratorService.getPendingVerifications();
      if (mounted) setState(() => _pending = data);
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
                  'Verify Location Information',
                  style: TextStyle(color: _P.deepNavy, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                if (_pending.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'All locations verified ✓',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _P.inkSoft, fontSize: 16),
                    ),
                  )
                else
                  ..._pending.map((loc) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.05), blurRadius: 12)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.name, style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('${loc.address} · ${loc.category}', style: const TextStyle(color: _P.inkSoft, fontSize: 12)),
                            Text('${loc.lat}, ${loc.lng}', style: const TextStyle(color: _P.inkSoft, fontSize: 12)),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await AdministratorService.rejectVerification(loc);
                                      _load();
                                    },
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await AdministratorService.approveVerification(loc);
                                      _load();
                                    },
                                    icon: const Icon(Icons.check_rounded, size: 18),
                                    label: const Text('Verify'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF43A047),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

// ── Reports ───────────────────────────────────────────────────────────

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await AdministratorService.getReportStats();
      if (mounted) setState(() => _stats = stats);
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
                  'Tourism Reports',
                  style: TextStyle(color: _P.deepNavy, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 500 ? 2 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    DashboardStatCard(
                      title: 'Total Bookings',
                      value: '${_stats['totalVisits'] ?? 0}',
                      icon: Icons.people_rounded,
                      accent: _P.blue,
                    ),
                    DashboardStatCard(
                      title: 'Verified Establishments',
                      value: '${_stats['verifiedEstablishments'] ?? 0}',
                      icon: Icons.store_rounded,
                      accent: const Color(0xFF43A047),
                    ),
                    DashboardStatCard(
                      title: 'Pending Verifications',
                      value: '${_stats['pendingVerifications'] ?? 0}',
                      icon: Icons.pending_actions_rounded,
                      accent: const Color(0xFFFFA726),
                    ),
                    DashboardStatCard(
                      title: 'Inactive Destinations',
                      value: '${_stats['inactiveDestinations'] ?? 0}',
                      icon: Icons.block_rounded,
                      accent: Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
