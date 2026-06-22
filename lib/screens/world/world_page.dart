import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/palette.dart';

typedef _P = AppPalette;

// ═══════════════════════════════════════════════════════════════════
//  DATA MODEL
// ═══════════════════════════════════════════════════════════════════

class MapPlace {
  final String name;
  final String location;
  final double rating;
  final String category;
  final LatLng coords;
  final List<Color> gradient;

  const MapPlace({
    required this.name,
    required this.location,
    required this.rating,
    required this.category,
    required this.coords,
    required this.gradient,
  });
}

// ═══════════════════════════════════════════════════════════════════
//  PLACES DATABASE
// ═══════════════════════════════════════════════════════════════════

const _allPlaces = <MapPlace>[
  // Beach
  MapPlace(name: 'Kaputian Beach', location: 'Kaputian, Samal', rating: 4.8, category: 'Beach', coords: LatLng(7.0568, 125.7230), gradient: [_P.skyBlue, _P.blue]),
  MapPlace(name: 'Vanishing Island', location: 'Babak District', rating: 4.7, category: 'Beach', coords: LatLng(7.0600, 125.7400), gradient: [_P.blue, _P.navy]),
  MapPlace(name: 'Secdea Beach Resort', location: 'Babak, Samal', rating: 4.8, category: 'Beach', coords: LatLng(7.0720, 125.7350), gradient: [_P.skyBlue, _P.navy]),
  // Falls
  MapPlace(name: 'Hagimit Falls', location: 'Penaplata, Samal', rating: 4.7, category: 'Falls', coords: LatLng(7.0931, 125.7361), gradient: [_P.blue, _P.navy]),
  MapPlace(name: 'Camp Sabros Falls', location: 'Penaplata, Samal', rating: 4.5, category: 'Falls', coords: LatLng(7.0880, 125.7300), gradient: [_P.skyBlue, _P.blue]),
  // Mountain
  MapPlace(name: 'Mt. Puting Bato', location: 'Bali-Bali, Samal', rating: 4.6, category: 'Mountain', coords: LatLng(7.1050, 125.7200), gradient: [_P.navy, _P.deepNavy]),
  // Resort
  MapPlace(name: 'Pearl Farm Resort', location: 'Kaputian, Samal', rating: 4.9, category: 'Resort', coords: LatLng(7.0475, 125.7125), gradient: [_P.skyBlue, _P.blue]),
  MapPlace(name: 'Maxima Aquafun', location: 'Penaplata, Samal', rating: 4.6, category: 'Resort', coords: LatLng(7.0834, 125.7298), gradient: [_P.blue, _P.navy]),
  // Island
  MapPlace(name: 'Talikud Island', location: 'Kaputian District', rating: 4.8, category: 'Island', coords: LatLng(6.9950, 125.7000), gradient: [_P.skyBlue, _P.navy]),
  // Historical
  MapPlace(name: 'Monfort Bat Cave', location: 'Babak, Samal', rating: 4.5, category: 'Historical', coords: LatLng(7.0768, 125.7420), gradient: [_P.navy, _P.deepNavy]),
  MapPlace(name: 'Ligid Cave', location: 'Penaplata, Samal', rating: 4.4, category: 'Historical', coords: LatLng(7.0900, 125.7100), gradient: [_P.blue, _P.navy]),
];

// ═══════════════════════════════════════════════════════════════════
//  CATEGORIES
// ═══════════════════════════════════════════════════════════════════

const _categories = <Map<String, dynamic>>[
  {'name': 'All', 'icon': Icons.explore_rounded},
  {'name': 'Beach', 'icon': Icons.beach_access_rounded},
  {'name': 'Falls', 'icon': Icons.water_drop_rounded},
  {'name': 'Mountain', 'icon': Icons.landscape_rounded},
  {'name': 'Resort', 'icon': Icons.villa_rounded},
  {'name': 'Island', 'icon': Icons.sailing_rounded},
  {'name': 'Historical', 'icon': Icons.account_balance_rounded},
];

// ═══════════════════════════════════════════════════════════════════
//  WORLD PAGE
// ═══════════════════════════════════════════════════════════════════

class WorldPage extends StatefulWidget {
  const WorldPage({super.key});

  @override
  State<WorldPage> createState() => _WorldPageState();
}

class _WorldPageState extends State<WorldPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<MapPlace> get _filteredPlaces {
    if (_selectedCategory == 'All') return _allPlaces;
    return _allPlaces.where((p) => p.category == _selectedCategory).toList();
  }

  // ── Animate camera to a location ──────────────────────────────────
  void _flyTo(LatLng target, {double zoom = 15.0}) {
    final camera = _mapController.camera;
    final startLat = camera.center.latitude;
    final startLng = camera.center.longitude;
    final startZoom = camera.zoom;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    controller.addListener(() {
      final t = curvedAnimation.value;
      final lat = startLat + (target.latitude - startLat) * t;
      final lng = startLng + (target.longitude - startLng) * t;
      final z = startZoom + (zoom - startZoom) * t;
      _mapController.move(LatLng(lat, lng), z);
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Full-screen Map ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(7.085, 125.730),
              initialZoom: 12.0,
              minZoom: 5,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.samal.nav',
                maxZoom: 18,
              ),

              // ── Place Markers ──────────────────────────────────
              MarkerLayer(
                markers: _filteredPlaces.map((place) {
                  return Marker(
                    point: place.coords,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showMarkerDetail(place),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: place.gradient),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: place.gradient[1].withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Top Overlay: Search + Categories ────────────────────
          SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: _P.deepNavy.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: _P.navy, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: _P.deepNavy, fontSize: 15, fontWeight: FontWeight.w500),
                                decoration: const InputDecoration(
                                  hintText: 'Search places in Samal...',
                                  hintStyle: TextStyle(color: _P.inkSoft, fontSize: 14, fontWeight: FontWeight.w500),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _P.deepNavy,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Category Chips
                SizedBox(
                  height: 44,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final name = cat['name'] as String;
                          final icon = cat['icon'] as IconData;
                          final selected = _selectedCategory == name;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? _P.deepNavy : Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: _P.deepNavy.withValues(alpha: selected ? 0.2 : 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, color: selected ? _P.skyBlue : _P.navy, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: selected ? Colors.white : _P.deepNavy,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Overlay: Suggestion Cards ────────────────────
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 140,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _filteredPlaces.isEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('No places in this category yet',
                                style: TextStyle(color: _P.inkSoft, fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredPlaces.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (_, i) => _buildSuggestionCard(_filteredPlaces[i]),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SUGGESTION CARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSuggestionCard(MapPlace place) {
    return GestureDetector(
      onTap: () => _flyTo(place.coords),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: place.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: place.gradient[1].withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background circle
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Category badge + Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        place.category,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 12),
                          const SizedBox(width: 2),
                          Text(place.rating.toString(),
                              style: const TextStyle(color: _P.deepNavy, fontSize: 11, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
                // Bottom: Name + Location
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 12),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            place.location,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MARKER DETAIL POPUP
  // ═══════════════════════════════════════════════════════════════════

  void _showMarkerDetail(MapPlace place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _P.deepNavy.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title bar
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: place.gradient),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name,
                          style: const TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(place.location,
                          style: const TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _P.iceBlue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 16),
                      const SizedBox(width: 4),
                      Text(place.rating.toString(),
                          style: const TextStyle(color: _P.deepNavy, fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Category + Coordinates
            Row(
              children: [
                _detailChip(Icons.category_rounded, place.category),
                const SizedBox(width: 10),
                _detailChip(Icons.my_location_rounded,
                    '${place.coords.latitude.toStringAsFixed(4)}, ${place.coords.longitude.toStringAsFixed(4)}'),
              ],
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _flyTo(place.coords, zoom: 16);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _P.deepNavy,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Navigate', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _P.iceBlue,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.close_rounded, color: _P.deepNavy, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _P.iceBlue,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _P.blue, size: 14),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(color: _P.deepNavy, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
