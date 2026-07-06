import 'package:flutter/material.dart';
import '../../theme/palette.dart';
import '../../algorithms/moga_engine.dart';

typedef _P = AppPalette;

// ═══════════════════════════════════════════════════════════════════
//  ROUTE RESULTS PAGE
//  Shown after "Optimize route" — either a single-day RouteResult or a
//  multi-day ItineraryResult is supplied (never both).
// ═══════════════════════════════════════════════════════════════════

class PlanResultsPage extends StatefulWidget {
  final List<Destination> destinations;
  final RouteResult? dayResult;
  final ItineraryResult? itineraryResult;
  final DateTime tripStartDate;

  const PlanResultsPage({
    super.key,
    required this.destinations,
    required this.tripStartDate,
    this.dayResult,
    this.itineraryResult,
  }) : assert(dayResult != null || itineraryResult != null, 'Provide either dayResult or itineraryResult');

  @override
  State<PlanResultsPage> createState() => _PlanResultsPageState();
}

class _PlanResultsPageState extends State<PlanResultsPage> with SingleTickerProviderStateMixin {
  late AnimationController _revealController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  bool get _isDayResult => widget.dayResult != null;

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Beach': return Icons.beach_access_rounded;
      case 'Falls': return Icons.water_drop_rounded;
      case 'Mountain': return Icons.landscape_rounded;
      case 'Resort': return Icons.villa_rounded;
      case 'Island': return Icons.sailing_rounded;
      case 'Historical': return Icons.account_balance_rounded;
      default: return Icons.place_rounded;
    }
  }

  List<Color> _catGradient(String cat) {
    switch (cat) {
      case 'Beach': return [_P.skyBlue, _P.blue];
      case 'Falls': return [_P.blue, _P.navy];
      case 'Mountain': return [_P.navy, _P.deepNavy];
      case 'Resort': return [_P.skyBlue, _P.blue];
      case 'Island': return [_P.skyBlue, _P.navy];
      case 'Historical': return [_P.navy, _P.deepNavy];
      default: return [_P.blue, _P.navy];
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 18),
                  _buildHeroSummary(),
                  const SizedBox(height: 26),
                  AnimatedBuilder(
                    animation: _revealController,
                    builder: (context, child) {
                      final t = CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic).value;
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
                      );
                    },
                    child: _isDayResult ? _buildDayResultBody() : _buildItineraryResultBody(),
                  ),
                  const SizedBox(height: 28),
                  _buildViewMapButton(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _Tappable(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: _P.deepNavy, size: 17),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          _isDayResult ? 'Your Day Escape' : 'Your Itinerary',
          style: const TextStyle(color: _P.deepNavy, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ],
    );
  }

  // ── Hero summary card ───────────────────────────────────────────
  Widget _buildHeroSummary() {
    final double distKm;
    final double timeHrs;
    final int stops;
    final String subtitle;

    if (_isDayResult) {
      final r = widget.dayResult!;
      distKm = r.totalDistanceKm;
      timeHrs = r.totalTimeHours;
      stops = r.stopOrder.length;
      subtitle = _formatDate(widget.tripStartDate);
    } else {
      final r = widget.itineraryResult!;
      distKm = r.totalDistanceKm;
      timeHrs = r.days.fold(0.0, (sum, d) => sum + d.timeHours);
      stops = r.days.fold(0, (sum, d) => sum + d.stopOrder.length);
      subtitle = '${r.days.length}-day plan';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_P.deepNavy, _P.navy], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: _P.navy.withValues(alpha: 0.3), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Optimized by MOGA',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _heroStat(Icons.straighten_rounded, '${distKm.toStringAsFixed(1)} km', 'Distance'),
              _heroDivider(),
              _heroStat(Icons.schedule_rounded, '${timeHrs.toStringAsFixed(1)} hrs', 'Total time'),
              _heroDivider(),
              _heroStat(Icons.pin_drop_rounded, '$stops', 'Stops'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() => Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.15));

  Widget _heroStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: _P.skyBlue, size: 19),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Day result body ─────────────────────────────────────────────
  Widget _buildDayResultBody() {
    final result = widget.dayResult!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Route order', 'Stop-by-stop, in the order MOGA recommends.'),
        const SizedBox(height: 18),
        _buildTimelineRail(result.stopOrder, result.legDistances, result.legTravelMins),
      ],
    );
  }

  // ── Itinerary result body ───────────────────────────────────────
  Widget _buildItineraryResultBody() {
    final result = widget.itineraryResult!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Day-by-day plan', '${result.days.length} days, optimized individually.'),
        const SizedBox(height: 18),
        ...result.days.map((day) => _buildDayCard(day)),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6, height: 22,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_P.skyBlue, _P.blue], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCard(DayPlan day) {
    final date = widget.tripStartDate.add(Duration(days: day.dayNumber - 1));
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _P.iceBlue, width: 1.2),
        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_P.deepNavy, _P.navy]),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text('Day ${day.dayNumber}',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Text(_formatDate(date), style: const TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(50)),
                child: Text('${day.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(color: _P.navy, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineRail(day.stopOrder, day.legDistances, day.legTravelMins),
        ],
      ),
    );
  }

  /// Continuous rail running through every stop, numbered beads on top,
  /// travel-leg pills overlapping the line.
  Widget _buildTimelineRail(List<int> stopOrder, List<double> legDistances, List<double> legTravelMins) {
    return Stack(
      children: [
        Positioned(
          left: 17.5,
          top: 18,
          bottom: 18,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_P.blue.withValues(alpha: 0.35), _P.skyBlue.withValues(alpha: 0.15)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Column(
          children: List.generate(stopOrder.length, (i) {
            final destIdx = stopOrder[i];
            final dest = widget.destinations[destIdx];
            final isLast = i == stopOrder.length - 1;

            return Column(
              children: [
                _buildTimelineStop(i + 1, dest, isLast),
                if (!isLast && i < legTravelMins.length)
                  _buildTravelLeg(legDistances[i], legTravelMins[i]),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimelineStop(int number, Destination dest, bool isLast) {
    final gradient = _catGradient(dest.category);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: gradient[1].withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Center(
              child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _P.iceBlue.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dest.name, style: const TextStyle(color: _P.deepNavy, fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, color: _P.inkSoft, size: 12),
                        const SizedBox(width: 3),
                        Expanded(child: Text(dest.location,
                            style: const TextStyle(color: _P.inkSoft, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_catIcon(dest.category), color: _P.blue, size: 12),
                      const SizedBox(width: 4),
                      Text('${dest.visitHours}h', style: const TextStyle(color: _P.navy, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTravelLeg(double distKm, double travelMins) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(width: 50),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _P.iceBlue, width: 1.2),
              boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.03), blurRadius: 6)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_car_rounded, color: _P.skyBlue, size: 14),
                const SizedBox(width: 6),
                Text('${distKm.toStringAsFixed(1)} km · ${travelMins.toStringAsFixed(0)} min',
                    style: const TextStyle(color: _P.inkSoft, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── View Map Button ─────────────────────────────────────────────
  Widget _buildViewMapButton(BuildContext context) {
    return _Tappable(
      onTap: () {
        Navigator.of(context).pushReplacementNamed('/map', arguments: {'isTabSwitch': true});
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_P.blue, _P.deepNavy], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _P.blue.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_rounded, color: Colors.white, size: 21),
            SizedBox(width: 10),
            Text('View your route on the map',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.1)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  _Tappable — shared tactile press feedback
// ═══════════════════════════════════════════════════════════════════

class _Tappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Tappable({required this.child, required this.onTap});

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}