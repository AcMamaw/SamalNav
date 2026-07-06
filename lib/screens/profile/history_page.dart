import 'package:flutter/material.dart';
import '../../theme/palette.dart';

typedef _P = AppPalette;

// ── Data model for a history entry ───────────────────────────────────
class RouteHistoryEntry {
  final String title;
  final String subtitle;
  final String date;
  final String type; // 'Day Tour' or 'Itinerary'
  final int stops;
  final double totalKm;
  final List<String> places;
  final List<Color> gradient;

  const RouteHistoryEntry({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
    required this.stops,
    required this.totalKm,
    required this.places,
    required this.gradient,
  });
}

// ── Mock history data ─────────────────────────────────────────────────
const _mockHistory = <RouteHistoryEntry>[
  RouteHistoryEntry(
    title: '3-Day Island Itinerary',
    subtitle: 'Pearl Farm → Talikud → Hagimit Falls',
    date: 'June 20, 2026',
    type: 'Itinerary',
    stops: 8,
    totalKm: 34.5,
    places: ['Pearl Farm Resort', 'Talikud Island', 'Hagimit Falls', 'Maxima Aquafun', 'Secdea Beach', 'Monfort Bat Cave', 'Vanishing Island', 'Kaputian Beach'],
    gradient: [_P.skyBlue, _P.deepNavy],
  ),
  RouteHistoryEntry(
    title: 'Single Day Beach Tour',
    subtitle: 'Kaputian → Vanishing Island → Isla Reta',
    date: 'June 25, 2026',
    type: 'Day Tour',
    stops: 3,
    totalKm: 12.1,
    places: ['Kaputian Beach', 'Vanishing Island', 'Isla Reta Beach'],
    gradient: [_P.blue, _P.navy],
  ),
  RouteHistoryEntry(
    title: 'Mountain & Falls Adventure',
    subtitle: 'Hagimit Falls → Mt. Puting Bato → Ligid Cave',
    date: 'June 28, 2026',
    type: 'Day Tour',
    stops: 3,
    totalKm: 18.7,
    places: ['Hagimit Falls', 'Mt. Puting Bato', 'Ligid Cave'],
    gradient: [_P.navy, _P.deepNavy],
  ),
  RouteHistoryEntry(
    title: '5-Day Samal Explorer',
    subtitle: 'Complete island exploration circuit',
    date: 'June 10, 2026',
    type: 'Itinerary',
    stops: 11,
    totalKm: 61.4,
    places: ['Kaputian Beach', 'Pearl Farm Resort', 'Hagimit Falls', 'Maxima Aquafun', 'Monfort Bat Cave', 'Talikud Island', 'Vanishing Island', 'Mt. Puting Bato', 'Secdea Beach', 'Ligid Cave', 'Bali-Bali View Deck'],
    gradient: [_P.skyBlue, _P.blue],
  ),
];

// ═══════════════════════════════════════════════════════════════════
//  HISTORY PAGE
// ═══════════════════════════════════════════════════════════════════

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String _filter = 'All'; // All, Day Tour, Itinerary

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<RouteHistoryEntry> get _filtered {
    if (_filter == 'All') return _mockHistory;
    return _mockHistory.where((h) => h.type == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: _P.white,
                boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _P.iceBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: _P.deepNavy, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Route History', style: TextStyle(color: _P.deepNavy, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                            Text('Your past plans & itineraries', style: TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(12)),
                        child: Text('${_mockHistory.length} trips', style: const TextStyle(color: _P.blue, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Filter chips
                  Row(
                    children: ['All', 'Day Tour', 'Itinerary'].map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? _P.deepNavy : Colors.transparent,
                              border: Border.all(color: selected ? _P.deepNavy : _P.inkSoft.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(f, style: TextStyle(color: selected ? Colors.white : _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ── List ───────────────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, color: _P.inkSoft, size: 56),
                          SizedBox(height: 16),
                          Text('No history yet', style: TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800)),
                          SizedBox(height: 6),
                          Text('Generate a route to see your trips here.', style: TextStyle(color: _P.inkSoft, fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final anim = CurvedAnimation(
                          parent: _animController,
                          curve: Interval(i * 0.15, (i * 0.15 + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
                        );
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                            child: _buildHistoryCard(_filtered[i]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(RouteHistoryEntry entry) {
    final isDayTour = entry.type == 'Day Tour';
    return GestureDetector(
      onTap: () => _showHistoryDetail(entry),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: entry.gradient, begin: Alignment.topLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: entry.gradient[1].withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(top: -20, right: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          children: [
                            Icon(isDayTour ? Icons.wb_sunny_rounded : Icons.calendar_month_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(entry.type, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(entry.date, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(entry.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                  const SizedBox(height: 6),
                  Text(entry.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      _statChip(Icons.place_rounded, '${entry.stops} stops'),
                      const SizedBox(width: 8),
                      _statChip(Icons.route_rounded, '${entry.totalKm} km'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Row(
                          children: [
                            Text('View', style: TextStyle(color: _P.deepNavy, fontSize: 12, fontWeight: FontWeight.w800)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, color: _P.deepNavy, size: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showHistoryDetail(RouteHistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: _P.inkSoft.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(50))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.title, style: const TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(50)),
                      child: Text(entry.date, style: const TextStyle(color: _P.blue, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _statChipDark(Icons.place_rounded, '${entry.stops} stops'),
                    const SizedBox(width: 8),
                    _statChipDark(Icons.route_rounded, '${entry.totalKm} km'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(alignment: Alignment.centerLeft, child: Text('Stops in this route:', style: TextStyle(color: _P.deepNavy, fontSize: 15, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: entry.places.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: entry.gradient),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.places[i], style: const TextStyle(color: _P.deepNavy, fontSize: 14, fontWeight: FontWeight.w600))),
                        const Icon(Icons.chevron_right_rounded, color: _P.inkSoft, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Regenerating this route in Plan tab...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        backgroundColor: _P.blue,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_P.blue, _P.deepNavy]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Re-use This Route', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChipDark(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(50)),
      child: Row(
        children: [
          Icon(icon, color: _P.blue, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: _P.deepNavy, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

