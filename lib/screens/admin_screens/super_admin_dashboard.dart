import 'package:flutter/material.dart';
import '../../models/app_role.dart';
import '../../models/audit_log_record.dart';
import '../../models/user_profile_record.dart';
import '../../services/role_service.dart';
import '../../services/super_admin_service.dart';
import '../../theme/palette.dart';
import '../../utils/time_utils.dart';
import '../../widgets/role_dashboard_shell.dart';

typedef _P = AppPalette;

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleService.guardRoute(
        context,
        allowedRoles: const [AppRole.superAdmin],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleDashboardShell(
      role: AppRole.superAdmin,
      subtitle: 'System Control Center',
      navItems: const [
        RoleNavItem(icon: Icons.monitor_heart_rounded, label: 'Activity'),
        RoleNavItem(icon: Icons.build_circle_rounded, label: 'Maintenance'),
        RoleNavItem(icon: Icons.history_rounded, label: 'Audit Log'),
        RoleNavItem(icon: Icons.admin_panel_settings_rounded, label: 'Users'),
      ],
      pages: const [
        _ActivityTab(),
        _MaintenanceTab(),
        _AuditLogTab(),
        _UserRolesTab(),
      ],
    );
  }
}

// ── Activity ──────────────────────────────────────────────────────────

class _ActivityTab extends StatefulWidget {
  const _ActivityTab();

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  Map<String, int> _roleCounts = {};
  List<AuditLogRecord> _activities = [];
  int _actionsToday = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final counts = await SuperAdminService.getUserStatsByRole();
      final activities = await SuperAdminService.getRecentActivity(limit: 15);
      final today = await SuperAdminService.getActionsTodayCount();
      if (mounted) {
        setState(() {
          _roleCounts = counts;
          _activities = activities;
          _actionsToday = today;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _roleColor(String? role) => switch (role) {
        'tourist' => _P.blue,
        'establishment' => const Color(0xFF43A047),
        'administrator' => const Color(0xFFFFA726),
        'super_admin' => Colors.redAccent,
        _ => _P.inkSoft,
      };

  String _roleLabel(String? role) => AppRole.fromString(role).label;

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
                  'Monitor User Activities',
                  style: TextStyle(color: _P.deepNavy, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                  children: [
                    DashboardStatCard(
                      title: 'Tourists',
                      value: '${_roleCounts['tourist'] ?? 0}',
                      icon: Icons.person_rounded,
                      accent: _P.blue,
                    ),
                    DashboardStatCard(
                      title: 'Establishments',
                      value: '${_roleCounts['establishment'] ?? 0}',
                      icon: Icons.store_rounded,
                      accent: const Color(0xFF43A047),
                    ),
                    DashboardStatCard(
                      title: 'Administrators',
                      value: '${_roleCounts['administrator'] ?? 0}',
                      icon: Icons.admin_panel_settings_rounded,
                      accent: const Color(0xFFFFA726),
                    ),
                    DashboardStatCard(
                      title: 'Actions Today',
                      value: '$_actionsToday',
                      icon: Icons.bolt_rounded,
                      accent: _P.navy,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const DashboardSectionHeader(title: 'Recent Activity'),
                const SizedBox(height: 12),
                if (_activities.isEmpty)
                  const _EmptyBox(message: 'No activity logged yet.')
                else
                  ..._activities.map((a) {
                    final color = _roleColor(a.userRole);
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
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(Icons.person_rounded, color: color, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      a.userEmail ?? 'System',
                                      style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    if (a.userRole != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          _roleLabel(a.userRole),
                                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(a.description, style: const TextStyle(color: _P.inkSoft, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(formatTimeAgo(a.createdAt), style: const TextStyle(color: _P.inkSoft, fontSize: 11)),
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

// ── Maintenance ───────────────────────────────────────────────────────

class _MaintenanceTab extends StatefulWidget {
  const _MaintenanceTab();

  @override
  State<_MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<_MaintenanceTab> {
  bool _maintenanceMode = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final mode = await SuperAdminService.getMaintenanceMode();
      if (mounted) setState(() => _maintenanceMode = mode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _P.blue));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perform System Maintenance',
                style: TextStyle(color: _P.deepNavy, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              _MaintenanceCard(
                icon: Icons.construction_rounded,
                title: 'Maintenance Mode',
                subtitle: 'Temporarily disable tourist access for system updates.',
                trailing: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(
                        value: _maintenanceMode,
                        activeThumbColor: _P.blue,
                        onChanged: (val) async {
                          setState(() => _saving = true);
                          await SuperAdminService.setMaintenanceMode(val);
                          if (mounted) {
                            setState(() {
                              _maintenanceMode = val;
                              _saving = false;
                            });
                          }
                        },
                      ),
              ),
              const _MaintenanceCard(
                icon: Icons.system_update_rounded,
                title: 'App Version',
                subtitle: 'SamalNav v1.0.0 — stored in system_settings table',
                trailing: Icon(Icons.check_circle_rounded, color: Color(0xFF43A047)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _MaintenanceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.05), blurRadius: 12)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _P.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(color: _P.inkSoft, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ── Audit Log ─────────────────────────────────────────────────────────

class _AuditLogTab extends StatefulWidget {
  const _AuditLogTab();

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  List<AuditLogRecord> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final logs = await SuperAdminService.getAuditLogs();
      if (mounted) setState(() => _logs = logs);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _typeColor(String type) => switch (type) {
        'LOGIN' => _P.blue,
        'UPDATE' => const Color(0xFFFFA726),
        'VERIFY' => const Color(0xFF43A047),
        'PAYMENT' => _P.navy,
        'MAINT' => Colors.purple,
        'ROLE' => Colors.redAccent,
        'BOOKING' => _P.skyBlue,
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
                const Text(
                  'View Audit Log',
                  style: TextStyle(color: _P.deepNavy, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                if (_logs.isEmpty)
                  const _EmptyBox(message: 'No audit entries yet.')
                else
                  ..._logs.map((log) {
                    final color = _typeColor(log.actionType);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _P.iceBlue),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.actionType,
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log.description, style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(
                                  '${log.userEmail ?? 'system'} · ${formatDateTime(log.createdAt)}',
                                  style: const TextStyle(color: _P.inkSoft, fontSize: 11),
                                ),
                              ],
                            ),
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

// ── User Roles ────────────────────────────────────────────────────────

class _UserRolesTab extends StatefulWidget {
  const _UserRolesTab();

  @override
  State<_UserRolesTab> createState() => _UserRolesTabState();
}

class _UserRolesTabState extends State<_UserRolesTab> {
  List<UserProfileRecord> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await SuperAdminService.getAllUsers();
      if (mounted) setState(() => _users = users);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(UserProfileRecord user) async {
    final selected = await showModalBottomSheet<AppRole>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppRole.values.map((role) {
            return ListTile(
              leading: Icon(Icons.badge_rounded, color: _roleColor(role)),
              title: Text(role.label),
              onTap: () => Navigator.pop(ctx, role),
            );
          }).toList(),
        ),
      ),
    );

    if (selected == null) return;
    await SuperAdminService.updateUserRole(user.id, selected);
    _load();
  }

  Color _roleColor(AppRole role) => switch (role) {
        AppRole.tourist => _P.blue,
        AppRole.establishmentOwner => const Color(0xFF43A047),
        AppRole.administrator => const Color(0xFFFFA726),
        AppRole.superAdmin => Colors.redAccent,
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
                const Text(
                  'Manage User Roles',
                  style: TextStyle(color: _P.deepNavy, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap edit to assign Tourist, Establishment Owner, Administrator, or Super Admin.',
                  style: TextStyle(color: _P.inkSoft, fontSize: 14),
                ),
                const SizedBox(height: 20),
                if (_users.isEmpty)
                  const _EmptyBox(message: 'No users in profiles table.')
                else
                  ..._users.map((u) {
                    final role = AppRole.fromString(u.role);
                    final color = _roleColor(role);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(Icons.person_rounded, color: color, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.displayName ?? u.email ?? 'User',
                                  style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w700),
                                ),
                                Text(u.email ?? '', style: const TextStyle(color: _P.inkSoft, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(role.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: _P.inkSoft, size: 20),
                            onPressed: () => _changeRole(u),
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

class _EmptyBox extends StatelessWidget {
  final String message;
  const _EmptyBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _P.inkSoft)),
    );
  }
}
