import 'package:flutter/material.dart';
import '../../theme/palette.dart';
import '../../algorithms/moga_engine.dart';

typedef _P = AppPalette;

// ═══════════════════════════════════════════════════════════════════
//  SAMAL ISLAND DESTINATIONS (shared data)
// ═══════════════════════════════════════════════════════════════════

const _samalDestinations = <Destination>[
  Destination(name: 'Kaputian Beach', location: 'Kaputian, Samal', lat: 7.0568, lng: 125.7230, visitHours: 1.5, category: 'Beach'),
  Destination(name: 'Pearl Farm Resort', location: 'Kaputian, Samal', lat: 7.0475, lng: 125.7125, visitHours: 3.0, category: 'Resort'),
  Destination(name: 'Hagimit Falls', location: 'Penaplata, Samal', lat: 7.0931, lng: 125.7361, visitHours: 1.5, category: 'Falls'),
  Destination(name: 'Maxima Aquafun', location: 'Penaplata, Samal', lat: 7.0834, lng: 125.7298, visitHours: 2.0, category: 'Resort'),
  Destination(name: 'Monfort Bat Cave', location: 'Babak, Samal', lat: 7.0768, lng: 125.7420, visitHours: 1.0, category: 'Historical'),
  Destination(name: 'Talikud Island', location: 'Kaputian District', lat: 6.9950, lng: 125.7000, visitHours: 3.0, category: 'Island'),
  Destination(name: 'Vanishing Island', location: 'Babak District', lat: 7.0600, lng: 125.7400, visitHours: 2.0, category: 'Beach'),
  Destination(name: 'Mt. Puting Bato', location: 'Bali-Bali, Samal', lat: 7.1050, lng: 125.7200, visitHours: 2.5, category: 'Mountain'),
  Destination(name: 'Secdea Beach Resort', location: 'Babak, Samal', lat: 7.0720, lng: 125.7350, visitHours: 2.0, category: 'Beach'),
  Destination(name: 'Ligid Cave', location: 'Penaplata, Samal', lat: 7.0900, lng: 125.7100, visitHours: 1.0, category: 'Historical'),
  Destination(name: 'Camp Sabros Falls', location: 'Penaplata, Samal', lat: 7.0880, lng: 125.7300, visitHours: 1.5, category: 'Falls'),
];

// ═══════════════════════════════════════════════════════════════════
//  ROUTE PAGE
// ═══════════════════════════════════════════════════════════════════

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> with SingleTickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────
  bool _isDayTour = true; // true = Day Tour, false = Itinerary
  DateTime _selectedDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  final Set<int> _selectedDestinations = {};
  bool _isOptimizing = false;
  RouteResult? _dayResult;
  ItineraryResult? _itineraryResult;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Icon for category ─────────────────────────────────────────
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

  // ── Run MOGA ──────────────────────────────────────────────────
  Future<void> _optimize() async {
    if (_selectedDestinations.isEmpty) return;

    setState(() {
      _isOptimizing = true;
      _dayResult = null;
      _itineraryResult = null;
    });

    // Small delay so the UI shows the loading state
    await Future.delayed(const Duration(milliseconds: 300));

    final selected = _selectedDestinations.toList()..sort();
    final dests = selected.map((i) => _samalDestinations[i]).toList();

    final engine = MogaEngine(
      destinations: dests,
      tourHours: 9.0,
      avgSpeedKmh: 30.0,
      populationSize: 50,
      generations: 100,
    );

    if (_isDayTour) {
      final result = engine.optimizeDayTour();
      // Map back to original indices
      final mappedOrder = result.stopOrder.map((i) => selected[i]).toList();
      setState(() {
        _dayResult = RouteResult(
          stopOrder: mappedOrder,
          totalDistanceKm: result.totalDistanceKm,
          totalTimeHours: result.totalTimeHours,
          legDistances: result.legDistances,
          legTravelMins: result.legTravelMins,
        );
        _isOptimizing = false;
      });
    } else {
      final days = _endDate.difference(_selectedDate).inDays + 1;
      final result = engine.optimizeItinerary(days);
      // Map back indices
      final mappedDays = result.days.map((day) {
        return DayPlan(
          dayNumber: day.dayNumber,
          stopOrder: day.stopOrder.map((i) => selected[i]).toList(),
          distanceKm: day.distanceKm,
          timeHours: day.timeHours,
          legDistances: day.legDistances,
          legTravelMins: day.legTravelMins,
        );
      }).toList();
      setState(() {
        _itineraryResult = ItineraryResult(days: mappedDays, totalDistanceKm: result.totalDistanceKm);
        _isOptimizing = false;
      });
    }
  }

  // ── Date Picker ───────────────────────────────────────────────
  Future<void> _pickDate({bool isEnd = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEnd ? _endDate : _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _P.deepNavy,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _P.deepNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isEnd) {
          _endDate = picked;
        } else {
          _selectedDate = picked;
          if (_endDate.isBefore(_selectedDate)) {
            _endDate = _selectedDate.add(const Duration(days: 1));
          }
        }
      });
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
                  const Text('Route Planner',
                      style: TextStyle(color: _P.deepNavy, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('Optimized with MOGA algorithm for the best travel experience.',
                      style: TextStyle(color: _P.inkSoft, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 28),

                  // ── Tour Mode Toggle ────────────────────────────
                  _buildModeSelector(),
                  const SizedBox(height: 24),

                  // ── Date Picker ─────────────────────────────────
                  _buildDateSection(),
                  const SizedBox(height: 28),

                  // ── Destination Selector ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Destinations',
                          style: TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                      Text('${_selectedDestinations.length} selected',
                          style: const TextStyle(color: _P.blue, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildDestinationList(),
                  const SizedBox(height: 28),

                  // ── Optimize Button ─────────────────────────────
                  _buildOptimizeButton(),
                  const SizedBox(height: 28),

                  // ── Results ─────────────────────────────────────
                  if (_dayResult != null) _buildDayResults(),
                  if (_itineraryResult != null) _buildItineraryResults(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TOUR MODE SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(child: _modeCard(
          icon: Icons.wb_sunny_rounded,
          title: 'Day Tour',
          subtitle: 'Explore in a single day',
          isSelected: _isDayTour,
          onTap: () => setState(() {
            _isDayTour = true;
            _dayResult = null;
            _itineraryResult = null;
          }),
        )),
        const SizedBox(width: 14),
        Expanded(child: _modeCard(
          icon: Icons.calendar_month_rounded,
          title: 'Itinerary',
          subtitle: 'Multi-day adventure',
          isSelected: !_isDayTour,
          onTap: () => setState(() {
            _isDayTour = false;
            _dayResult = null;
            _itineraryResult = null;
          }),
        )),
      ],
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_P.deepNavy, _P.navy], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _P.navy.withValues(alpha: 0.3) : _P.deepNavy.withValues(alpha: 0.05),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.15) : _P.iceBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isSelected ? _P.skyBlue : _P.blue, size: 22),
            ),
            const SizedBox(height: 14),
            Text(title, style: TextStyle(
              color: isSelected ? Colors.white : _P.deepNavy,
              fontSize: 16, fontWeight: FontWeight.w800,
            )),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(
              color: isSelected ? Colors.white70 : _P.inkSoft,
              fontSize: 12, fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DATE SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDateSection() {
    if (_isDayTour) {
      return _dateChip(
        label: 'Tour Date',
        date: _selectedDate,
        onTap: () => _pickDate(),
      );
    }
    return Row(
      children: [
        Expanded(child: _dateChip(label: 'Start Date', date: _selectedDate, onTap: () => _pickDate())),
        const SizedBox(width: 14),
        Expanded(child: _dateChip(label: 'End Date', date: _endDate, onTap: () => _pickDate(isEnd: true))),
      ],
    );
  }

  Widget _dateChip({required String label, required DateTime date, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.calendar_today_rounded, color: _P.blue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: _P.inkSoft, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_formatDate(date), style: const TextStyle(color: _P.deepNavy, fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _P.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DESTINATION LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDestinationList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _samalDestinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final dest = _samalDestinations[i];
        final selected = _selectedDestinations.contains(i);
        final gradient = _catGradient(dest.category);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedDestinations.remove(i);
              } else {
                _selectedDestinations.add(i);
              }
              // Clear results when selection changes
              _dayResult = null;
              _itineraryResult = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? _P.deepNavy : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? _P.blue : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected ? _P.navy.withValues(alpha: 0.2) : _P.deepNavy.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Gradient icon
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_catIcon(dest.category), color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dest.name, style: TextStyle(
                        color: selected ? Colors.white : _P.deepNavy,
                        fontSize: 15, fontWeight: FontWeight.w800,
                      )),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: selected ? Colors.white54 : _P.inkSoft, size: 12),
                          const SizedBox(width: 3),
                          Expanded(child: Text(dest.location, style: TextStyle(
                            color: selected ? Colors.white54 : _P.inkSoft,
                            fontSize: 12, fontWeight: FontWeight.w500,
                          ), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Duration chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withValues(alpha: 0.12) : _P.iceBlue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, color: selected ? _P.skyBlue : _P.blue, size: 12),
                      const SizedBox(width: 4),
                      Text('${dest.visitHours}h', style: TextStyle(
                        color: selected ? _P.skyBlue : _P.navy,
                        fontSize: 12, fontWeight: FontWeight.w700,
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: selected ? _P.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? _P.blue : _P.inkSoft.withValues(alpha: 0.3), width: 2),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  OPTIMIZE BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOptimizeButton() {
    final hasSelection = _selectedDestinations.isNotEmpty;
    return GestureDetector(
      onTap: hasSelection && !_isOptimizing ? _optimize : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: hasSelection
              ? const LinearGradient(colors: [_P.blue, _P.deepNavy])
              : null,
          color: hasSelection ? null : _P.iceBlue,
          borderRadius: BorderRadius.circular(50),
          boxShadow: hasSelection
              ? [BoxShadow(color: _P.blue.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isOptimizing)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            else
              Icon(Icons.auto_fix_high_rounded,
                  color: hasSelection ? Colors.white : _P.inkSoft, size: 20),
            const SizedBox(width: 10),
            Text(
              _isOptimizing ? 'Running MOGA Optimization...' : 'Optimize Route',
              style: TextStyle(
                color: hasSelection ? Colors.white : _P.inkSoft,
                fontSize: 16, fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DAY TOUR RESULTS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDayResults() {
    final result = _dayResult!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Optimized Route', style: TextStyle(color: _P.deepNavy, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text('MOGA found the best order for your ${result.stopOrder.length} destinations.',
            style: const TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),

        // Summary chips
        _buildSummaryRow(result.totalDistanceKm, result.totalTimeHours, result.stopOrder.length),
        const SizedBox(height: 20),

        // Route timeline
        ...List.generate(result.stopOrder.length, (i) {
          final destIdx = result.stopOrder[i];
          final dest = _samalDestinations[destIdx];
          final isLast = i == result.stopOrder.length - 1;

          return Column(
            children: [
              _buildTimelineStop(i + 1, dest, isLast),
              if (!isLast && i < result.legTravelMins.length)
                _buildTravelLeg(result.legDistances[i], result.legTravelMins[i]),
            ],
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ITINERARY RESULTS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildItineraryResults() {
    final result = _itineraryResult!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Itinerary', style: TextStyle(color: _P.deepNavy, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text('${result.days.length}-day plan optimized by MOGA.',
            style: const TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),

        // Total summary
        _buildSummaryRow(
          result.totalDistanceKm,
          result.days.fold(0.0, (sum, d) => sum + d.timeHours),
          result.days.fold(0, (sum, d) => sum + d.stopOrder.length),
        ),
        const SizedBox(height: 24),

        // Each day
        ...result.days.map((day) => _buildDayCard(day)),
      ],
    );
  }

  Widget _buildDayCard(DayPlan day) {
    final date = _selectedDate.add(Duration(days: day.dayNumber - 1));
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_P.deepNavy, _P.navy]),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text('Day ${day.dayNumber}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
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
          const SizedBox(height: 18),

          // Stops
          ...List.generate(day.stopOrder.length, (i) {
            final dest = _samalDestinations[day.stopOrder[i]];
            final isLast = i == day.stopOrder.length - 1;
            return Column(
              children: [
                _buildTimelineStop(i + 1, dest, isLast),
                if (!isLast && i < day.legTravelMins.length)
                  _buildTravelLeg(day.legDistances[i], day.legTravelMins[i]),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHARED RESULT WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryRow(double distKm, double timeHrs, int stops) {
    return Row(
      children: [
        _summaryChip(Icons.straighten_rounded, '${distKm.toStringAsFixed(1)} km', 'Distance'),
        const SizedBox(width: 10),
        _summaryChip(Icons.schedule_rounded, '${timeHrs.toStringAsFixed(1)} hrs', 'Total Time'),
        const SizedBox(width: 10),
        _summaryChip(Icons.pin_drop_rounded, '$stops', 'Stops'),
      ],
    );
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _P.iceBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: _P.blue, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: _P.deepNavy, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: _P.inkSoft, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStop(int number, Destination dest, bool isLast) {
    final gradient = _catGradient(dest.category);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot + line
        SizedBox(
          width: 36,
          child: Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: gradient[1].withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Center(
                  child: Text('$number',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Stop info
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _P.iceBlue.withValues(alpha: 0.5),
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
                      Text('${dest.visitHours}h',
                          style: const TextStyle(color: _P.navy, fontSize: 12, fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          // Dotted line
          Column(
            children: List.generate(3, (_) => Container(
              width: 3, height: 6,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(color: _P.skyBlue.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
            )),
          ),
          const SizedBox(width: 18),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.04), blurRadius: 8)],
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
}
