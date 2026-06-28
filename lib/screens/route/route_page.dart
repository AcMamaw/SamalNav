import 'package:flutter/material.dart';
import '../../theme/palette.dart';
import '../../algorithms/moga_engine.dart';
import '../../state/app_state.dart';
import 'package:latlong2/latlong.dart';
import 'route_results_page.dart';

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

// ── Cosmetic-only placeholder info (rating + blurb), keyed by index.
// Not part of your real Destination model — purely for the detail sheet
// until real photos/ratings/descriptions are wired in.
const _placeholderRatings = <double>[4.8, 4.9, 4.7, 4.6, 4.5, 4.8, 4.7, 4.6, 4.8, 4.4, 4.5];
const _placeholderBlurbs = <String>[
  'A wide stretch of pale sand facing the Davao Gulf, calm enough for swimming most of the year.',
  'A long-running pearl farm turned resort, with cabanas built out over clear water.',
  'A set of cascading freshwater pools a short walk from the road, popular for a midday dip.',
  'A water park with slides and pools built for a full-day family visit.',
  'Home to one of the largest colonies of fruit bats in the world, viewable up close.',
  'A quieter island off Kaputian with thinner crowds and good snorkeling reefs.',
  'A sandbar that shrinks and grows with the tide, walkable to at low water.',
  'A modest peak with a clear view back over the channel toward Davao City.',
  'A beach resort with simple cottages, good for an unhurried overnight stay.',
  'A small limestone cave system near Penaplata, lightly developed for visitors.',
  'A second falls near Camp Sabros, less crowded than Hagimit on most days.',
];

// ═══════════════════════════════════════════════════════════════════
//  ROUTE PAGE
// ═══════════════════════════════════════════════════════════════════

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────
  bool _isDayTour = true; // true = Day Escape, false = Itinerary Escape
  DateTime _selectedDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));

  // Day Escape: a single shared selection set.
  final Set<int> _selectedDestinations = {};
  String _daySearchQuery = '';

  // Itinerary Escape: one selection set + one search query PER day.
  List<Set<int>> _dayDestinations = [];
  List<String> _daySearchQueries = [];

  bool _isOptimizing = false;

  late AnimationController _pulseController; // idle "ready" breathing pulse
  late AnimationController _listController; // staggered entrance for destination list

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _syncDayBuckets();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _listController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int get _tripDays => _endDate.difference(_selectedDate).inDays + 1;

  /// Keeps _dayDestinations / _daySearchQueries sized to the current
  /// date range, preserving existing picks when the range grows/shrinks.
  void _syncDayBuckets() {
    final days = _tripDays.clamp(1, 365);
    while (_dayDestinations.length < days) {
      _dayDestinations.add({});
      _daySearchQueries.add('');
    }
    while (_dayDestinations.length > days) {
      _dayDestinations.removeLast();
      _daySearchQueries.removeLast();
    }
  }

  /// True if [destIndex] was already picked on an earlier day than [dayIndex].
  bool _isUsedOnEarlierDay(int destIndex, int dayIndex) {
    for (var d = 0; d < dayIndex; d++) {
      if (_dayDestinations[d].contains(destIndex)) return true;
    }
    return false;
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

  // ── Run MOGA, then push the results page ───────────────────────
  Future<void> _optimize() async {
    final hasSelection = _isDayTour
        ? _selectedDestinations.isNotEmpty
        : _dayDestinations.any((s) => s.isNotEmpty);
    if (!hasSelection) return;

    setState(() => _isOptimizing = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (_isDayTour) {
      final selected = _selectedDestinations.toList()..sort();
      final dests = selected.map((i) => _samalDestinations[i]).toList();

      final engine = MogaEngine(
        destinations: dests,
        tourHours: 9.0,
        avgSpeedKmh: 30.0,
        populationSize: 50,
        generations: 100,
      );

      final result = engine.optimizeDayTour();
      final mappedOrder = result.stopOrder.map((i) => selected[i]).toList();
      final dayResult = RouteResult(
        stopOrder: mappedOrder,
        totalDistanceKm: result.totalDistanceKm,
        totalTimeHours: result.totalTimeHours,
        legDistances: result.legDistances,
        legTravelMins: result.legTravelMins,
      );

      final polyline = mappedOrder
          .map((idx) => LatLng(_samalDestinations[idx].lat, _samalDestinations[idx].lng))
          .toList();
      AppState.setActivePolyline(polyline);

      if (!mounted) return;
      setState(() => _isOptimizing = false);

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RouteResultsPage(
          destinations: _samalDestinations,
          dayResult: dayResult,
          tripStartDate: _selectedDate,
        ),
      ));
    } else {
      // Build one combined destination list, but keep per-day grouping so
      // the engine can optimize within each day's stops.
      final dayIndexLists = _dayDestinations.map((s) => s.toList()..sort()).toList();
      final allSelected = dayIndexLists.expand((l) => l).toSet().toList()..sort();

      if (allSelected.isEmpty) {
        setState(() => _isOptimizing = false);
        return;
      }

      final dests = allSelected.map((i) => _samalDestinations[i]).toList();
      final engine = MogaEngine(
        destinations: dests,
        tourHours: 9.0,
        avgSpeedKmh: 30.0,
        populationSize: 50,
        generations: 100,
      );

      final result = engine.optimizeItinerary(_tripDays);
      final mappedDays = result.days.map((day) {
        return DayPlan(
          dayNumber: day.dayNumber,
          stopOrder: day.stopOrder.map((i) => allSelected[i]).toList(),
          distanceKm: day.distanceKm,
          timeHours: day.timeHours,
          legDistances: day.legDistances,
          legTravelMins: day.legTravelMins,
        );
      }).toList();

      final itineraryResult = ItineraryResult(days: mappedDays, totalDistanceKm: result.totalDistanceKm);

      final polyline = mappedDays
          .expand((d) => d.stopOrder)
          .map((idx) => LatLng(_samalDestinations[idx].lat, _samalDestinations[idx].lng))
          .toList();
      AppState.setActivePolyline(polyline);

      if (!mounted) return;
      setState(() => _isOptimizing = false);

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RouteResultsPage(
          destinations: _samalDestinations,
          itineraryResult: itineraryResult,
          tripStartDate: _selectedDate,
        ),
      ));
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
        _syncDayBuckets();
      });
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _relativeDayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return _formatDate(d);
  }

  // ── Detail sheet ────────────────────────────────────────────────
  void _openDetailSheet(int destIndex, {required bool isSelected, required VoidCallback onToggle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DestinationDetailSheet(
        destination: _samalDestinations[destIndex],
        rating: _placeholderRatings[destIndex],
        blurb: _placeholderBlurbs[destIndex],
        gradient: _catGradient(_samalDestinations[destIndex].category),
        icon: _catIcon(_samalDestinations[destIndex].category),
        isSelected: isSelected,
        onToggleSelect: () {
          onToggle();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    _syncDayBuckets();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildModeSelector(),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SizeTransition(sizeFactor: anim, child: child),
                    ),
                    child: _buildDateSection(),
                  ),
                  const SizedBox(height: 28),

                  // ── Mode-specific content ──────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isDayTour ? _buildDayEscapeSection() : _buildItineraryEscapeSection(),
                  ),

                  const SizedBox(height: 26),
                  _buildOptimizeButton(),
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
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_P.skyBlue, _P.blue],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Route Planner',
                      style: TextStyle(color: _P.deepNavy, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.0)),
                ],
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text('Plotted stop-by-stop by the MOGA engine for the fewest backtracks.',
                    style: TextStyle(color: _P.inkSoft, fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.3)),
              ),
            ],
          ),
        ),
      ],
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
          title: 'Day Escape',
          subtitle: 'One day, One destination',
          isSelected: _isDayTour,
          onTap: () => setState(() => _isDayTour = true),
        )),
        const SizedBox(width: 12),
        Expanded(child: _modeCard(
          icon: Icons.calendar_month_rounded,
          title: 'Itinerary Escape',
          subtitle: 'Multiple Destinations',
          isSelected: !_isDayTour,
          onTap: () => setState(() => _isDayTour = false),
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
    return _Tappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_P.deepNavy, _P.navy], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? Colors.transparent : _P.iceBlue,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _P.navy.withValues(alpha: 0.28) : _P.deepNavy.withValues(alpha: 0.04),
              blurRadius: isSelected ? 18 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.15) : _P.iceBlue,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: isSelected ? _P.skyBlue : _P.blue, size: 21),
                ),
                if (isSelected)
                  Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: _P.deepNavy, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: TextStyle(
              color: isSelected ? Colors.white : _P.deepNavy,
              fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2,
            )),
            const SizedBox(height: 3),
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
        key: const ValueKey('day'),
        label: 'Tour date',
        date: _selectedDate,
        onTap: () => _pickDate(),
      );
    }
    return Row(
      key: const ValueKey('range'),
      children: [
        Expanded(child: _dateChip(label: 'Start date', date: _selectedDate, onTap: () => _pickDate())),
        const SizedBox(width: 12),
        Expanded(child: _dateChip(label: 'End date', date: _endDate, onTap: () => _pickDate(isEnd: true))),
      ],
    );
  }

  Widget _dateChip({Key? key, required String label, required DateTime date, required VoidCallback onTap}) {
    return _Tappable(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.iceBlue, width: 1.2),
          boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.calendar_today_rounded, color: _P.blue, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: _P.inkSoft, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                  const SizedBox(height: 2),
                  Text(_formatDate(date), style: const TextStyle(color: _P.deepNavy, fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _P.inkSoft, size: 19),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DAY ESCAPE SECTION (single shared picker)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDayEscapeSection() {
    return Column(
      key: const ValueKey('dayEscape'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Select destination',
                style: TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            _selectedCountBadge(_selectedDestinations.length),
          ],
        ),
        const SizedBox(height: 14),
        _searchField(
          hint: 'Search tourist spots…',
          onChanged: (v) => setState(() => _daySearchQuery = v),
        ),
        const SizedBox(height: 14),
        _buildPictureList(
          query: _daySearchQuery,
          isSelected: (i) => _selectedDestinations.contains(i),
          dimmedIndices: const {},
          onToggle: (i) => setState(() {
            if (_selectedDestinations.contains(i)) {
              _selectedDestinations.remove(i);
            } else {
              _selectedDestinations.add(i);
            }
          }),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ITINERARY ESCAPE SECTION (per-day pickers)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildItineraryEscapeSection() {
    return Column(
      key: const ValueKey('itineraryEscape'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6, height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_P.skyBlue, _P.blue], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Text('Itinerary Escape',
                style: const TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text('Multiple Destinations • $_tripDays Day Itinerary',
              style: const TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 18),
        ...List.generate(_tripDays, (dayIdx) => _buildDayBlock(dayIdx)),
      ],
    );
  }

  Widget _buildDayBlock(int dayIdx) {
    final date = _selectedDate.add(Duration(days: dayIdx));
    final picks = _dayDestinations[dayIdx];
    final isExpanded = picks.isNotEmpty || dayIdx == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _P.iceBlue, width: 1.2),
        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          tilePadding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_P.deepNavy, _P.navy]),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text('Day ${dayIdx + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_relativeDayLabel(date),
                    style: const TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              _selectedCountBadge(picks.length),
            ],
          ),
          children: [
            _searchField(
              hint: 'Search tourist spots for this day…',
              onChanged: (v) => setState(() => _daySearchQueries[dayIdx] = v),
            ),
            const SizedBox(height: 12),
            _buildPictureList(
              query: _daySearchQueries[dayIdx],
              isSelected: (i) => picks.contains(i),
              dimmedIndices: {
                for (var i = 0; i < _samalDestinations.length; i++)
                  if (_isUsedOnEarlierDay(i, dayIdx)) i,
              },
              onToggle: (i) => setState(() {
                if (picks.contains(i)) {
                  picks.remove(i);
                } else {
                  picks.add(i);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedCountBadge(int count) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(count),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: count == 0 ? _P.iceBlue : _P.blue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text('$count selected',
            style: TextStyle(
              color: count == 0 ? _P.inkSoft : _P.blue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            )),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SEARCH FIELD
  // ═══════════════════════════════════════════════════════════════

  Widget _searchField({required String hint, required ValueChanged<String> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _P.iceBlue.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _P.iceBlue, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _P.navy, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(color: _P.deepNavy, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _P.inkSoft, fontSize: 13.5, fontWeight: FontWeight.w500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PICTURE-CARD DESTINATION LIST (shared by both modes)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPictureList({
    required String query,
    required bool Function(int) isSelected,
    required Set<int> dimmedIndices,
    required void Function(int) onToggle,
  }) {
    final q = query.trim().toLowerCase();
    final indices = List.generate(_samalDestinations.length, (i) => i).where((i) {
      if (q.isEmpty) return true;
      final d = _samalDestinations[i];
      return d.name.toLowerCase().contains(q) ||
          d.location.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q);
    }).toList();

    if (indices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text('No spots match "$query"',
              style: const TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: indices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, listIdx) {
        final i = indices[listIdx];
        final dest = _samalDestinations[i];
        final selected = isSelected(i);
        final dimmed = dimmedIndices.contains(i) && !selected;
        final gradient = _catGradient(dest.category);

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: dimmed ? 0.45 : 1.0,
          child: _DestinationPictureCard(
            name: dest.name,
            location: dest.location,
            visitHours: dest.visitHours,
            icon: _catIcon(dest.category),
            gradient: gradient,
            isSelected: selected,
            onTap: () => _openDetailSheet(i, isSelected: selected, onToggle: () => onToggle(i)),
            onQuickToggle: () => onToggle(i),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  OPTIMIZE BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOptimizeButton() {
    final hasSelection = _isDayTour
        ? _selectedDestinations.isNotEmpty
        : _dayDestinations.any((s) => s.isNotEmpty);

    return _Tappable(
      onTap: hasSelection && !_isOptimizing ? _optimize : null,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse = hasSelection && !_isOptimizing ? _pulseController.value : 0.0;
          return AnimatedContainer(
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
                  ? [BoxShadow(color: _P.blue.withValues(alpha: 0.28 + (pulse * 0.14)), blurRadius: 18 + (pulse * 8), offset: const Offset(0, 8))]
                  : null,
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isOptimizing)
              const SizedBox(
                width: 19, height: 19,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            else
              Icon(Icons.auto_fix_high_rounded,
                  color: hasSelection ? Colors.white : _P.inkSoft, size: 20),
            const SizedBox(width: 10),
            Text(
              _isOptimizing ? 'Running MOGA optimization…' : 'Optimize route',
              style: TextStyle(
                color: hasSelection ? Colors.white : _P.inkSoft,
                fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DESTINATION PICTURE CARD — image-1 layout, image-2/3 banner styling
// ═══════════════════════════════════════════════════════════════════

class _DestinationPictureCard extends StatelessWidget {
  final String name;
  final String location;
  final double visitHours;
  final IconData icon;
  final List<Color> gradient;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onQuickToggle;

  const _DestinationPictureCard({
    required this.name,
    required this.location,
    required this.visitHours,
    required this.icon,
    required this.gradient,
    required this.isSelected,
    required this.onTap,
    required this.onQuickToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _P.blue : _P.iceBlue, width: isSelected ? 1.8 : 1.2),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _P.blue.withValues(alpha: 0.18) : _P.deepNavy.withValues(alpha: 0.04),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo banner placeholder — swap for Image.network/asset later.
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -16,
                          bottom: -16,
                          child: Icon(icon, size: 92, color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        Center(child: Icon(icon, size: 34, color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onQuickToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: isSelected ? _P.blue : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Icon(
                        isSelected ? Icons.check_rounded : Icons.add_rounded,
                        color: isSelected ? Colors.white : _P.navy,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, color: _P.blue, size: 12),
                        const SizedBox(width: 4),
                        Text('${visitHours}h',
                            style: const TextStyle(color: _P.navy, fontSize: 11.5, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: _P.deepNavy, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.1)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: _P.inkSoft, size: 12),
                            const SizedBox(width: 3),
                            Expanded(child: Text(location,
                                style: const TextStyle(color: _P.inkSoft, fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: _P.inkSoft.withValues(alpha: 0.5), size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DESTINATION DETAIL SHEET — image-3 layout, Select instead of Book Now
// ═══════════════════════════════════════════════════════════════════

class _DestinationDetailSheet extends StatefulWidget {
  final Destination destination;
  final double rating;
  final String blurb;
  final List<Color> gradient;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onToggleSelect;

  const _DestinationDetailSheet({
    required this.destination,
    required this.rating,
    required this.blurb,
    required this.gradient,
    required this.icon,
    required this.isSelected,
    required this.onToggleSelect,
  });

  @override
  State<_DestinationDetailSheet> createState() => _DestinationDetailSheetState();
}

class _DestinationDetailSheetState extends State<_DestinationDetailSheet> {
  int _tabIndex = 0;
  static const _tabs = ['Overview', 'Map', 'Tips'];

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(50)),
                ),
              ),
              const SizedBox(height: 16),

              // Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: widget.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(widget.icon, size: 130, color: Colors.white.withValues(alpha: 0.16)),
                        ),
                        Center(child: Icon(widget.icon, size: 48, color: Colors.white.withValues(alpha: 0.92))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title row + price-style duration chip (kept consistent with the rest of the app)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dest.name,
                              style: const TextStyle(color: _P.deepNavy, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: _P.inkSoft, size: 14),
                              const SizedBox(width: 4),
                              Text(dest.location, style: const TextStyle(color: _P.inkSoft, fontSize: 13.5, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(50)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded, color: _P.blue, size: 14),
                          const SizedBox(width: 5),
                          Text('${dest.visitHours}h',
                              style: const TextStyle(color: _P.navy, fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Rating row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < widget.rating.floor();
                        final half = !filled && i < widget.rating;
                        return Icon(
                          half ? Icons.star_half_rounded : (filled ? Icons.star_rounded : Icons.star_border_rounded),
                          color: const Color(0xFFFFA726),
                          size: 17,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.rating.toString(),
                        style: const TextStyle(color: _P.deepNavy, fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(50)),
                      child: Text(dest.category,
                          style: const TextStyle(color: _P.navy, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = _tabIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 22),
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = i),
                        child: Column(
                          children: [
                            Text(_tabs[i],
                                style: TextStyle(
                                  color: selected ? _P.deepNavy : _P.inkSoft,
                                  fontSize: 14,
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                )),
                            const SizedBox(height: 6),
                            Container(
                              height: 3,
                              width: 28,
                              decoration: BoxDecoration(
                                color: selected ? _P.blue : Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Divider(height: 1, color: _P.iceBlue),
              const SizedBox(height: 16),

              // Tab content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _buildTabContent(dest),
              ),
              const SizedBox(height: 24),

              // Select button (replaces "Book Now!")
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                child: _Tappable(
                  onTap: widget.onToggleSelect,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      gradient: widget.isSelected
                          ? null
                          : const LinearGradient(colors: [_P.blue, _P.deepNavy]),
                      color: widget.isSelected ? _P.iceBlue : null,
                      borderRadius: BorderRadius.circular(50),
                      border: widget.isSelected ? Border.all(color: _P.blue, width: 1.6) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                          color: widget.isSelected ? _P.blue : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          widget.isSelected ? 'Selected — tap to remove' : 'Select this spot',
                          style: TextStyle(
                            color: widget.isSelected ? _P.blue : Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabContent(Destination dest) {
    switch (_tabIndex) {
      case 1: // Map
        return Container(
          height: 140,
          decoration: BoxDecoration(color: _P.iceBlue.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_rounded, color: _P.blue, size: 28),
              const SizedBox(height: 8),
              Text('${dest.lat.toStringAsFixed(4)}, ${dest.lng.toStringAsFixed(4)}',
                  style: const TextStyle(color: _P.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Full map preview available after optimizing',
                  style: TextStyle(color: _P.inkSoft, fontSize: 11.5, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      case 2: // Tips
        return const Text(
          'Bring water and sun protection. Most Samal Island spots are best visited in the morning before the midday heat and weekend crowds.',
          style: TextStyle(color: _P.inkSoft, fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.5),
        );
      default: // Overview
        return Text(
          widget.blurb,
          style: const TextStyle(color: _P.inkSoft, fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.5),
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  _Tappable — shared tactile press feedback (subtle scale, no bounce)
// ═══════════════════════════════════════════════════════════════════

class _Tappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Tappable({super.key, required this.child, required this.onTap});

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