import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/palette.dart';
import '../../state/app_state.dart';

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
  final PageController _cardController = PageController(viewportFraction: 0.62);

  LatLng? _currentLocation;
  List<LatLng> _routePolyline = [];

  late AnimationController _markerDropController;
  double _cardPage = 0;
  int? _focusedPlaceIndex;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _checkActiveRoute();

    _markerDropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _cardController.addListener(() {
      setState(() => _cardPage = _cardController.page ?? 0);
    });
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    }

    // Continuously listen to location updates
    Geolocator.getPositionStream().listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  void _checkActiveRoute() {
    if (AppState.hasActiveRoute && AppState.activeRoutePolyline != null) {
      _routePolyline = AppState.activeRoutePolyline!;

      if (_routePolyline.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _flyTo(_routePolyline.first, zoom: 12.0);
        });
      }
    }
  }

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

  void _onSuggestionTap(int index, MapPlace place) {
    _cardController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    setState(() => _focusedPlaceIndex = index);
    _flyTo(place.coords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _cardController.dispose();
    _markerDropController.dispose();
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

              // ── Route Polyline ─────────────────────────────────
              if (_routePolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePolyline,
                      color: _P.blue,
                      strokeWidth: 4.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // ── Place Markers ──────────────────────────────────
              MarkerLayer(
                markers: [
                  ..._filteredPlaces.asMap().entries.map((entry) {
                    final i = entry.key;
                    final place = entry.value;
                    final isFocused = _focusedPlaceIndex != null &&
                        _filteredPlaces[_focusedPlaceIndex!] == place;
                    return Marker(
                      point: place.coords,
                      width: isFocused ? 50 : 40,
                      height: isFocused ? 50 : 40,
                      child: _DroppingMarker(
                        delay: Duration(milliseconds: 40 * i),
                        controller: _markerDropController,
                        child: GestureDetector(
                          onTap: () => _showMarkerDetail(place),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: place.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: isFocused ? 3 : 2),
                              boxShadow: [
                                BoxShadow(
                                  color: place.gradient[1].withValues(alpha: isFocused ? 0.55 : 0.4),
                                  blurRadius: isFocused ? 14 : 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(Icons.location_on_rounded, color: Colors.white, size: isFocused ? 24 : 20),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 50,
                      height: 50,
                      child: const _CurrentLocationMarker(),
                    ),
                ],
              ),
            ],
          ),

          // ── Top Overlay: Glass control deck ─────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _GlassPanel(
                        borderRadius: 26,
                        child: Column(
                          children: [
                            // Search row
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: _P.navy, size: 21),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: const TextStyle(color: _P.deepNavy, fontSize: 15, fontWeight: FontWeight.w500),
                                      decoration: const InputDecoration(
                                        hintText: 'Search places in Samal…',
                                        hintStyle: TextStyle(color: _P.inkSoft, fontSize: 14, fontWeight: FontWeight.w500),
                                        border: InputBorder.none,
                                        isCollapsed: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [_P.blue, _P.deepNavy]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 17),
                                  ),
                                ],
                              ),
                            ),
                            Container(height: 1, color: _P.deepNavy.withValues(alpha: 0.06)),
                            // Category chips, inside the same glass panel
                            SizedBox(
                              height: 50,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                itemCount: _categories.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final cat = _categories[i];
                                  final name = cat['name'] as String;
                                  final icon = cat['icon'] as IconData;
                                  final selected = _selectedCategory == name;
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedCategory = name;
                                      _focusedPlaceIndex = null;
                                    }),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: selected ? const LinearGradient(colors: [_P.deepNavy, _P.navy]) : null,
                                        color: selected ? null : _P.iceBlue.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(icon, color: selected ? _P.skyBlue : _P.navy, size: 15),
                                          const SizedBox(width: 6),
                                          Text(
                                            name,
                                            style: TextStyle(
                                              color: selected ? Colors.white : _P.deepNavy,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Overlay: Carousel suggestion cards ───────────
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 152,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _filteredPlaces.isEmpty
                      ? Center(
                          child: _GlassPanel(
                            borderRadius: 20,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              child: Text('No places in this category yet',
                                  style: TextStyle(color: _P.inkSoft, fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        )
                      : PageView.builder(
                          controller: _cardController,
                          itemCount: _filteredPlaces.length,
                          padEnds: true,
                          onPageChanged: (i) => setState(() => _focusedPlaceIndex = i),
                          itemBuilder: (_, i) {
                            final delta = (_cardPage - i).abs().clamp(0.0, 1.0);
                            final scale = 1.0 - (delta * 0.12);
                            final opacity = 1.0 - (delta * 0.35);
                            return Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: opacity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 7),
                                  child: _buildSuggestionCard(_filteredPlaces[i], i),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),

          // ── My Location FAB ─────────────────────────────────────
          Positioned(
            bottom: 175,
            right: 18,
            child: _GlassFab(
              icon: Icons.my_location_rounded,
              onTap: () {
                if (_currentLocation != null) {
                  _flyTo(_currentLocation!, zoom: 15.0);
                } else {
                  _flyTo(const LatLng(7.085, 125.730), zoom: 12.0);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SUGGESTION CARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSuggestionCard(MapPlace place, int index) {
    return GestureDetector(
      onTap: () => _onSuggestionTap(index, place),
      child: Container(
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
            Row(
              children: [
                _detailChip(Icons.category_rounded, place.category),
                const SizedBox(width: 10),
                _detailChip(Icons.my_location_rounded,
                    '${place.coords.latitude.toStringAsFixed(4)}, ${place.coords.longitude.toStringAsFixed(4)}'),
              ],
            ),
            const SizedBox(height: 20),
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
                        gradient: const LinearGradient(colors: [_P.blue, _P.deepNavy]),
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

// ═══════════════════════════════════════════════════════════════════
//  GLASS PANEL — frosted backdrop-blur container, the deck's material
// ═══════════════════════════════════════════════════════════════════

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const _GlassPanel({required this.child, this.borderRadius = 22});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: _P.deepNavy.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassFab extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassFab({required this.icon, required this.onTap});

  @override
  State<_GlassFab> createState() => _GlassFabState();
}

class _GlassFabState extends State<_GlassFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_P.deepNavy, _P.navy], begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _P.navy.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DROPPING MARKER — staggered drop-in on first paint
// ═══════════════════════════════════════════════════════════════════

class _DroppingMarker extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final AnimationController controller;

  const _DroppingMarker({required this.child, required this.delay, required this.controller});

  @override
  Widget build(BuildContext context) {
    final totalMs = controller.duration!.inMilliseconds;
    final delayMs = delay.inMilliseconds.clamp(0, totalMs - 1);
    final startT = delayMs / totalMs;
    final endT = (startT + 0.5).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(startT, endT, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -18),
            child: child,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CURRENT LOCATION MARKER
// ═══════════════════════════════════════════════════════════════════

class _CurrentLocationMarker extends StatefulWidget {
  const _CurrentLocationMarker();

  @override
  State<_CurrentLocationMarker> createState() => _CurrentLocationMarkerState();
}

class _CurrentLocationMarkerState extends State<_CurrentLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _P.blue.withValues(alpha: 0.2 + (_controller.value * 0.3)),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: _P.blue.withValues(alpha: 0.4),
                blurRadius: 10 * _controller.value,
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
          child: const Center(
            child: CircleAvatar(
              radius: 6,
              backgroundColor: _P.blue,
            ),
          ),
        );
      },
    );
  }
}