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
  final bool isClosed;
  final bool isUnderMaintenance;
  final String imageUrl;

  const MapPlace({
    required this.name,
    required this.location,
    required this.rating,
    required this.category,
    required this.coords,
    required this.gradient,
    this.isClosed = false,
    this.isUnderMaintenance = false,
    required this.imageUrl,
  });
}

// ═══════════════════════════════════════════════════════════════════
//  PLACES DATABASE
// ═══════════════════════════════════════════════════════════════════

const _allPlaces = <MapPlace>[
  // Beach
  MapPlace(
    name: 'Isla Reta Beach',
    location: 'Talikud Island, Samal',
    rating: 4.8,
    category: 'Beach',
    coords: LatLng(6.9360, 125.7597),
    gradient: [_P.skyBlue, _P.blue],
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80',
  ),
  MapPlace(
    name: 'Kaputian Beach',
    location: 'South Samal',
    rating: 4.9,
    category: 'Beach',
    coords: LatLng(6.9644, 125.7235),
    gradient: [_P.skyBlue, _P.navy],
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80',
  ),
  MapPlace(
    name: 'Canibad Beach',
    location: 'Babak District',
    rating: 4.6,
    category: 'Beach',
    coords: LatLng(7.1353, 125.7925),
    gradient: [_P.skyBlue, _P.blue],
    imageUrl: 'https://images.unsplash.com/photo-1439066615861-d1af74d74000?auto=format&fit=crop&w=500&q=80',
  ),
  MapPlace(
    name: 'Paradise Island',
    location: 'Penaplata, Samal',
    rating: 4.7,
    category: 'Beach',
    coords: LatLng(7.1158, 125.6881),
    gradient: [_P.skyBlue, _P.navy],
    imageUrl: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=500&q=80',
  ),
  MapPlace(
    name: 'Vanishing Island',
    location: 'Babak District',
    rating: 4.7,
    category: 'Beach',
    coords: LatLng(7.0700, 125.7100),
    gradient: [_P.blue, _P.navy],
    imageUrl: 'https://images.unsplash.com/photo-1473116763269-255448993f66?auto=format&fit=crop&w=500&q=80',
  ),
  // Falls
  MapPlace(
    name: 'Hagimit Falls',
    location: 'Penaplata, Samal',
    rating: 4.7,
    category: 'Falls',
    coords: LatLng(7.0666, 125.7230),
    gradient: [_P.blue, _P.navy],
    imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=500&q=80',
  ),
  // Mountain
  MapPlace(
    name: 'Mt. Puting Bato',
    location: 'Bali-Bali, Samal',
    rating: 4.6,
    category: 'Mountain',
    coords: LatLng(7.0656, 125.7681),
    gradient: [_P.navy, _P.deepNavy],
    imageUrl: 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=500&q=80',
  ),
  // Resort
  MapPlace(
    name: 'Pearl Farm Resort',
    location: 'Kaputian, Samal',
    rating: 4.9,
    category: 'Resort',
    coords: LatLng(7.0050, 125.7271),
    gradient: [_P.skyBlue, _P.blue],
    imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=500&q=80',
  ),
  MapPlace(
    name: 'Maxima Aquafun',
    location: 'Penaplata, Samal',
    rating: 4.6,
    category: 'Resort',
    coords: LatLng(7.0425, 125.7275),
    gradient: [_P.blue, _P.navy],
    imageUrl: 'https://images.unsplash.com/photo-1538964173425-93884d739596?auto=format&fit=crop&w=500&q=80',
  ),
  MapPlace(
    name: 'Bali-Bali View Deck',
    location: 'Penaplata, Samal',
    rating: 4.5,
    category: 'Resort',
    coords: LatLng(7.0125, 125.7198),
    gradient: [_P.blue, _P.navy],
    imageUrl: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=500&q=80',
  ),
  // Island
  MapPlace(
    name: 'Talikud Island',
    location: 'Kaputian District',
    rating: 4.8,
    category: 'Island',
    coords: LatLng(6.9322, 125.6987),
    gradient: [_P.skyBlue, _P.navy],
    imageUrl: 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=500&q=80',
  ),
  MapPlace(
    name: 'Coral Garden',
    location: 'Talikud, Samal',
    rating: 4.7,
    category: 'Island',
    coords: LatLng(6.9280, 125.7020),
    gradient: [_P.skyBlue, _P.navy],
    imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=500&q=80',
  ),
  // Historical
  MapPlace(
    name: 'Monfort Bat Cave',
    location: 'Babak, Samal',
    rating: 4.5,
    category: 'Historical',
    coords: LatLng(7.1260, 125.7140),
    gradient: [_P.navy, _P.deepNavy],
    imageUrl: 'https://images.unsplash.com/photo-1507163546605-a84d8ff1a3bb?auto=format&fit=crop&w=500&q=80',
  ),
  MapPlace(
    name: 'Ligid Island Cave',
    location: 'Penaplata, Samal',
    rating: 4.4,
    category: 'Historical',
    coords: LatLng(7.1850, 125.7550),
    gradient: [_P.blue, _P.navy],
    imageUrl: 'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?auto=format&fit=crop&w=500&q=80',
  ),
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

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final PageController _cardController = PageController(viewportFraction: 0.62);
  bool _isSatelliteMode = true;

  LatLng? _currentLocation;
  List<LatLng> _routePolyline = [];

  // Journey tracking
  bool _journeyStarted = false;
  int _completedStops = 0;

  late AnimationController _markerDropController;
  late AnimationController _carPulseController;
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

    _carPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

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
    _carPulseController.dispose();
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
              _isSatelliteMode
                  ? TileLayer(
                      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.samal.nav',
                      maxZoom: 19,
                    )
                  : TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.samal.nav',
                      maxZoom: 19,
                    ),

              // ── Route Polylines (red = remaining, green = completed) ──
              if (_routePolyline.length >= 2) ...[
                // Green: completed segments
                if (_journeyStarted && _completedStops > 0 && _completedStops < _routePolyline.length)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePolyline.sublist(0, _completedStops.clamp(0, _routePolyline.length)),
                        color: const Color(0xFF4CAF50),
                        strokeWidth: 5.0,
                        borderColor: Colors.white,
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),
                // Red or blue: remaining segments
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _journeyStarted
                          ? _routePolyline.sublist((_completedStops - 1).clamp(0, _routePolyline.length - 1))
                          : _routePolyline,
                      color: _journeyStarted ? const Color(0xFFE53935) : _P.blue,
                      strokeWidth: _journeyStarted ? 5.0 : 4.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
                // All green when journey completed
                if (_journeyStarted && _completedStops >= _routePolyline.length)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePolyline,
                        color: const Color(0xFF4CAF50),
                        strokeWidth: 5.0,
                        borderColor: Colors.white,
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),
              ],

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
                          onTap: place.isClosed ? null : () => _showMarkerDetail(place),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: place.isClosed
                                    ? [Colors.grey.shade400, Colors.grey.shade600]
                                    : place.isUnderMaintenance
                                        ? [const Color(0xFFFFCA28), const Color(0xFFF57F17)]
                                        : const [_P.skyBlue, _P.blue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: isFocused ? 3 : 2),
                              boxShadow: [
                                BoxShadow(
                                  color: (place.isClosed ? Colors.grey.shade600 : place.isUnderMaintenance ? const Color(0xFFF57F17) : _P.blue).withValues(alpha: isFocused ? 0.55 : 0.4),
                                  blurRadius: isFocused ? 14 : 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              place.isClosed ? Icons.lock_rounded : place.isUnderMaintenance ? Icons.construction_rounded : Icons.location_on_rounded, 
                              color: Colors.white, 
                              size: isFocused ? 24 : 20,
                            ),
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
                  // Car marker on the route
                  if (_journeyStarted && _routePolyline.isNotEmpty)
                    Marker(
                      point: _completedStops < _routePolyline.length
                          ? _routePolyline[_completedStops.clamp(0, _routePolyline.length - 1)]
                          : _routePolyline.last,
                      width: 56,
                      height: 56,
                      child: _CarMarker(pulseController: _carPulseController),
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
                                separatorBuilder: (_, _) => const SizedBox(width: 8),
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

          // ── Satellite Toggle FAB ────────────────────────────────
          Positioned(
            bottom: 235,
            right: 18,
            child: _GlassFab(
              icon: _isSatelliteMode
                  ? Icons.map_rounded
                  : Icons.satellite_alt_rounded,
              onTap: () {
                setState(() => _isSatelliteMode = !_isSatelliteMode);
              },
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

          // ── Journey Control FAB ──────────────────────────────────
          if (_routePolyline.isNotEmpty)
            Positioned(
              bottom: 175,
              left: 18,
              child: Column(
                children: [
                  // Start / Complete Journey button
                  if (!_journeyStarted)
                    GestureDetector(
                      onTap: () => setState(() {
                        _journeyStarted = true;
                        _completedStops = 0;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF388E3C)]),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text('Start Journey', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  if (_journeyStarted && _completedStops < _routePolyline.length)
                    GestureDetector(
                      onTap: () {
                        setState(() => _completedStops++);
                        if (_completedStops < _routePolyline.length) {
                          _flyTo(_routePolyline[_completedStops], zoom: 14.0);
                        }
                        if (_completedStops >= _routePolyline.length) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text('Journey Complete! 🎉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                ],
                              ),
                              backgroundColor: const Color(0xFF4CAF50),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFC62828)]),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text('Stop ${_completedStops + 1} ✓', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  if (_journeyStarted && _completedStops >= _routePolyline.length)
                    GestureDetector(
                      onTap: () => setState(() {
                        _journeyStarted = false;
                        _completedStops = 0;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_P.blue, _P.deepNavy]),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Reset', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                ],
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
          image: DecorationImage(
            image: NetworkImage(place.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.38),
              BlendMode.srcOver,
            ),
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
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
                 ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    place.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: place.gradient),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                    ),
                  ),
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
//  CAR MARKER (animated vehicle icon on route)
// ═══════════════════════════════════════════════════════════════════

class _CarMarker extends StatelessWidget {
  final AnimationController pulseController;

  const _CarMarker({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, _) {
        final scale = 1.0 + (pulseController.value * 0.12);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.redAccent, width: 3),
            ),
            child: const Center(
              child: Icon(
                Icons.location_on_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
            ),
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

