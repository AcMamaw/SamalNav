import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/destination_record.dart';

/// Central service that provides all destinations across the app.
///
/// Data sources (in priority order):
/// 1. **Supabase `destinations` table** — primary source of truth
/// 2. **In-memory cache** — for instant screen transitions
/// 3. **Hardcoded fallback** — works offline with 35+ verified Samal Island spots
///
/// The optional [fetchFromOverpassOsm] method can sync live OpenStreetMap
/// data into Supabase for admin review.
class DestinationService {
  static SupabaseClient get _client => Supabase.instance.client;

  // ── In-memory cache ─────────────────────────────────────────────
  static List<DestinationRecord>? _cache;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// Returns all active destinations from Supabase, falling back to
  /// the hardcoded list if the network request fails.
  static Future<List<DestinationRecord>> getAll({bool forceRefresh = false}) async {
    // Return cache if fresh
    if (!forceRefresh &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cache!;
    }

    try {
      final data = await _client
          .from('destinations')
          .select()
          .order('name');

      final records = (data as List)
          .map((row) => DestinationRecord.fromJson(row as Map<String, dynamic>))
          .where((d) => d.isActive)
          .toList();

      if (records.isNotEmpty) {
        _cache = records;
        _cacheTime = DateTime.now();
        return records;
      }
    } catch (e) {
      debugPrint('DestinationService.getAll: Supabase fetch failed: $e');
    }

    // Fallback to hardcoded data
    final fallback = _fallbackDestinations;
    _cache = fallback;
    _cacheTime = DateTime.now();
    return fallback;
  }

  /// Returns a single destination by name (case-insensitive).
  static Future<DestinationRecord?> getByName(String name) async {
    final all = await getAll();
    final lower = name.toLowerCase();
    try {
      return all.firstWhere((d) => d.name.toLowerCase() == lower);
    } catch (_) {
      return null;
    }
  }

  /// Returns destinations filtered by category.
  static Future<List<DestinationRecord>> getByCategory(String category) async {
    final all = await getAll();
    if (category == 'All') return all;
    return all.where((d) => d.category == category).toList();
  }

  /// Returns the distinct set of categories from all destinations.
  static Future<List<String>> getCategories() async {
    final all = await getAll();
    final cats = all.map((d) => d.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  /// Clears the in-memory cache.
  static void clearCache() {
    _cache = null;
    _cacheTime = null;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  OVERPASS / OSM SYNC (optional — for admin use)
  // ═══════════════════════════════════════════════════════════════════

  /// Fetches tourism/leisure/natural features from OpenStreetMap for
  /// the Samal Island bounding box via the Overpass API.
  ///
  /// Returns raw OSM elements (name, lat, lng, tags). These can be
  /// used to populate or validate the Supabase destinations table.
  static Future<List<Map<String, dynamic>>> fetchFromOverpassOsm() async {
    // Samal Island bounding box: south, west, north, east
    const bbox = '6.85,125.60,7.25,125.85';
    const query = '''
[out:json][timeout:30];
(
  node["tourism"~"resort|hotel|attraction|guest_house|motel|hostel"]($bbox);
  node["natural"="beach"]($bbox);
  node["waterway"="waterfall"]($bbox);
  node["leisure"~"park|resort|swimming_pool"]($bbox);
  node["historic"]($bbox);
  way["tourism"~"resort|hotel|attraction"]($bbox);
  way["natural"="beach"]($bbox);
);
out center;
''';

    try {
      final uri = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(uri, body: {'data': query});

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = json['elements'] as List? ?? [];

        return elements
            .where((e) {
              final tags = e['tags'] as Map<String, dynamic>?;
              return tags != null && tags['name'] != null;
            })
            .map((e) {
              final tags = e['tags'] as Map<String, dynamic>;
              final lat = (e['lat'] as num?)?.toDouble() ??
                  (e['center']?['lat'] as num?)?.toDouble() ??
                  0.0;
              final lng = (e['lon'] as num?)?.toDouble() ??
                  (e['center']?['lon'] as num?)?.toDouble() ??
                  0.0;

              return <String, dynamic>{
                'name': tags['name'],
                'lat': lat,
                'lng': lng,
                'category': _osmTagToCategory(tags),
                'location': tags['addr:city'] ?? tags['addr:municipality'] ?? 'Samal Island',
                'description': tags['description'] ?? '',
              };
            })
            .toList();
      }
    } catch (e) {
      debugPrint('DestinationService.fetchFromOverpassOsm error: $e');
    }

    return [];
  }

  static String _osmTagToCategory(Map<String, dynamic> tags) {
    final tourism = tags['tourism'] as String? ?? '';
    final natural = tags['natural'] as String? ?? '';
    final waterway = tags['waterway'] as String? ?? '';
    final leisure = tags['leisure'] as String? ?? '';
    final historic = tags['historic'] as String? ?? '';

    if (natural == 'beach') return 'Beach';
    if (waterway == 'waterfall') return 'Falls';
    if (tourism == 'resort' || leisure == 'resort') return 'Resort';
    if (tourism == 'hotel' || tourism == 'guest_house' || tourism == 'motel' || tourism == 'hostel') return 'Hotel';
    if (tourism == 'attraction') return 'Historical';
    if (historic.isNotEmpty) return 'Historical';
    if (leisure == 'park') return 'Forest';
    return 'Resort'; // default
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HARDCODED FALLBACK — 35+ verified Samal Island destinations
  // ═══════════════════════════════════════════════════════════════════

  static final List<DestinationRecord> _fallbackDestinations = [
    // ── Beaches ────────────────────────────────────────────────────
    const DestinationRecord(
      id: 'fb-001', name: 'Kaputian Beach', location: 'Kaputian, Samal',
      lat: 6.9736, lng: 125.7265, category: 'Beach', rating: 4.9,
      status: 'active', isVerified: true,
      description: 'A long stretch of fine white sand with calm, shallow waters perfect for families.',
      entranceFee: 100, averageStayMinutes: 90,
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-002', name: 'Isla Reta Beach', location: 'Talikud Island, Samal',
      lat: 6.9385, lng: 125.7115, category: 'Beach', rating: 4.8,
      status: 'active', isVerified: true,
      description: 'Crystal-clear waters and powdery white sand surrounded by lush coconut trees.',
      entranceFee: 150, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-003', name: 'Canibad Beach', location: 'Babak District, Samal',
      lat: 7.1353, lng: 125.7925, category: 'Beach', rating: 4.6,
      status: 'active', isVerified: true,
      description: 'Hidden cove with turquoise water, great for cliff diving and snorkeling.',
      entranceFee: 80, averageStayMinutes: 90,
      imageUrl: 'https://images.unsplash.com/photo-1439066615861-d1af74d74000?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-004', name: 'Paradise Island', location: 'Peñaplata, Samal',
      lat: 7.1147, lng: 125.6585, category: 'Beach', rating: 4.7,
      status: 'active', isVerified: true,
      description: 'Resort island with water sports, swimming pools, and beachfront cottages.',
      entranceFee: 250, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-005', name: 'Vanishing Island', location: 'Babak District, Samal',
      lat: 7.1290, lng: 125.6480, category: 'Beach', rating: 4.7,
      status: 'active', isVerified: true,
      description: 'A sandbar that appears only during low tide — a truly magical experience.',
      entranceFee: 300, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1473116763269-255448993f66?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-006', name: 'Babu Santa Beach', location: 'Babak District, Samal',
      lat: 7.1050, lng: 125.7780, category: 'Beach', rating: 4.4,
      status: 'active', isVerified: true,
      description: 'A quiet stretch of sand with calm waves, perfect for a peaceful day trip.',
      entranceFee: 50, averageStayMinutes: 90,
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80',
    ),
    // ── Resorts ────────────────────────────────────────────────────
    const DestinationRecord(
      id: 'fb-010', name: 'Pearl Farm Resort', location: 'Kaputian, Samal',
      lat: 7.0080, lng: 125.7170, category: 'Resort', rating: 4.9,
      status: 'active', isVerified: true,
      description: 'A long-running pearl farm turned resort, with cabanas built out over clear water.',
      entranceFee: 250, averageStayMinutes: 180,
      imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-011', name: 'Maxima Aquafun', location: 'Peñaplata, Samal',
      lat: 7.0425, lng: 125.7035, category: 'Resort', rating: 4.6,
      status: 'active', isVerified: true,
      description: 'A water park with slides, pools, and zip lines built for a full-day family visit.',
      entranceFee: 350, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1538964173425-93884d739596?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-012', name: 'Secdea Beach Resort', location: 'Babak, Samal',
      lat: 7.1690, lng: 125.7580, category: 'Resort', rating: 4.8,
      status: 'active', isVerified: true,
      description: 'A beach resort with simple cottages, good for an unhurried overnight stay.',
      entranceFee: 200, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-013', name: 'Bali-Bali View Deck', location: 'Peñaplata, Samal',
      lat: 7.0125, lng: 125.7130, category: 'Resort', rating: 4.5,
      status: 'active', isVerified: true,
      description: 'Mountain view deck overlooking the sea, perfect for sunset watching.',
      entranceFee: 30, averageStayMinutes: 90,
      imageUrl: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-014', name: 'Cavanico Bella Beach Resort', location: 'Babak, Samal',
      lat: 7.1290, lng: 125.7830, category: 'Resort', rating: 4.5,
      status: 'active', isVerified: true,
      description: 'Beachfront resort with modern rooms, an infinity pool, and stunning sunset views.',
      entranceFee: 200, averageStayMinutes: 150,
      imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-015', name: 'Club Samal Resort', location: 'Peñaplata, Samal',
      lat: 7.0985, lng: 125.6720, category: 'Resort', rating: 4.3,
      status: 'active', isVerified: true,
      description: 'A family-friendly resort with spacious grounds, pool, and beach access.',
      entranceFee: 150, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-016', name: "Chema's by the Sea", location: 'Peñaplata, Samal',
      lat: 7.0875, lng: 125.6790, category: 'Resort', rating: 4.4,
      status: 'active', isVerified: true,
      description: 'A cozy beachfront resort with seaside dining and a quiet atmosphere.',
      entranceFee: 100, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-017', name: 'Hof Gorei Beach Resort', location: 'Babak, Samal',
      lat: 7.1520, lng: 125.6680, category: 'Resort', rating: 4.6,
      status: 'active', isVerified: true,
      description: 'A tropical resort known for its hillside infinity pool and beachfront area.',
      entranceFee: 250, averageStayMinutes: 150,
      imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-018', name: 'Punta del Sol Beach Resort', location: 'Babak, Samal',
      lat: 7.0810, lng: 125.6750, category: 'Resort', rating: 4.3,
      status: 'active', isVerified: true,
      description: 'A seaside retreat with spacious rooms, a pool, and kayak rentals.',
      entranceFee: 150, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-019', name: 'Costa Marina Beach Resort', location: 'Babak, Samal',
      lat: 7.1160, lng: 125.6590, category: 'Resort', rating: 4.4,
      status: 'active', isVerified: true,
      description: 'A well-kept resort with a wide beachfront, water sports, and seaside restaurant.',
      entranceFee: 200, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-020', name: 'Camp Holiday Resort', location: 'Babak, Samal',
      lat: 7.1275, lng: 125.6655, category: 'Resort', rating: 4.2,
      status: 'active', isVerified: true,
      description: 'An adventure-themed resort with team-building facilities and nature trails.',
      entranceFee: 200, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1538964173425-93884d739596?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-021', name: 'Blue Waters Samal Resort', location: 'Peñaplata, Samal',
      lat: 7.0780, lng: 125.6830, category: 'Resort', rating: 4.3,
      status: 'active', isVerified: true,
      description: 'A budget-friendly resort with beachfront cottages and a peaceful vibe.',
      entranceFee: 100, averageStayMinutes: 90,
      imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-022', name: 'Precious Garden of Samal', location: 'Peñaplata, Samal',
      lat: 7.1350, lng: 125.6780, category: 'Resort', rating: 4.1,
      status: 'active', isVerified: true,
      description: 'A garden resort with themed cottages, event spaces, and swimming pools.',
      entranceFee: 120, averageStayMinutes: 90,
      imageUrl: 'https://images.unsplash.com/photo-1538964173425-93884d739596?auto=format&fit=crop&w=500&q=80',
    ),
    // ── Falls ──────────────────────────────────────────────────────
    const DestinationRecord(
      id: 'fb-030', name: 'Hagimit Falls', location: 'Peñaplata, Samal',
      lat: 7.0620, lng: 125.7085, category: 'Falls', rating: 4.7,
      status: 'active', isVerified: true,
      description: 'A set of cascading freshwater pools a short walk from the road, popular for a midday dip.',
      entranceFee: 50, averageStayMinutes: 90,
      imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-031', name: 'Tagbaobo Falls', location: 'Tagbaobo, Samal',
      lat: 7.0054, lng: 125.7750, category: 'Falls', rating: 4.5,
      status: 'active', isVerified: true,
      description: 'A scenic waterfall near Tagbaobo village, accessible via a short nature hike.',
      entranceFee: 30, averageStayMinutes: 90,
      imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=500&q=80',
    ),
    // ── Mountain ───────────────────────────────────────────────────
    const DestinationRecord(
      id: 'fb-040', name: 'Mt. Puting Bato', location: 'Bali-Bali, Samal',
      lat: 7.0656, lng: 125.7580, category: 'Mountain', rating: 4.6,
      status: 'active', isVerified: true,
      description: 'A modest peak with a clear view back over the channel toward Davao City.',
      entranceFee: 0, averageStayMinutes: 150,
      imageUrl: 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=500&q=80',
    ),
    // ── Islands ────────────────────────────────────────────────────
    const DestinationRecord(
      id: 'fb-050', name: 'Talikud Island', location: 'Kaputian District, Samal',
      lat: 6.9250, lng: 125.6950, category: 'Island', rating: 4.8,
      status: 'active', isVerified: true,
      description: 'A quieter island off Kaputian with thinner crowds and good snorkeling reefs.',
      entranceFee: 200, averageStayMinutes: 180,
      imageUrl: 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-051', name: 'Coral Garden', location: 'Talikud Island, Samal',
      lat: 6.9150, lng: 125.6850, category: 'Island', rating: 4.7,
      status: 'active', isVerified: true,
      description: 'Underwater paradise with vibrant coral formations and tropical fish.',
      entranceFee: 500, averageStayMinutes: 120,
      imageUrl: 'https://images.unsplash.com/photo-1546026423-cc4642628d2b?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-052', name: 'Malipano Island', location: 'Kaputian, Samal',
      lat: 7.0020, lng: 125.7150, category: 'Island', rating: 4.6,
      status: 'active', isVerified: true,
      description: 'A private island with pristine beaches, luxury villas, and coral reefs.',
      entranceFee: 0, averageStayMinutes: 180,
      imageUrl: 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=500&q=80',
    ),
    // ── Historical / Caves ─────────────────────────────────────────
    const DestinationRecord(
      id: 'fb-060', name: 'Monfort Bat Sanctuary', location: 'Babak, Samal',
      lat: 7.1650, lng: 125.6880, category: 'Historical', rating: 4.5,
      status: 'active', isVerified: true,
      description: 'Home to one of the largest colonies of fruit bats in the world, viewable up close.',
      entranceFee: 100, averageStayMinutes: 60,
      imageUrl: 'https://images.unsplash.com/photo-1507163546605-a84d8ff1a3bb?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-061', name: 'Ligid Island Cave', location: 'Peñaplata, Samal',
      lat: 7.1850, lng: 125.7550, category: 'Historical', rating: 4.4,
      status: 'active', isVerified: true,
      description: 'A challenging dive site known for its beautiful rock formations and marine life.',
      entranceFee: 100, averageStayMinutes: 60,
      imageUrl: 'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?auto=format&fit=crop&w=500&q=80',
    ),
    // ── Hotels ─────────────────────────────────────────────────────
    const DestinationRecord(
      id: 'fb-070', name: 'Samal Island Huts', location: 'Peñaplata, Samal',
      lat: 7.0850, lng: 125.6890, category: 'Hotel', rating: 4.2,
      status: 'active', isVerified: true,
      description: 'Budget-friendly huts with beachfront views and local hospitality.',
      entranceFee: 0, averageStayMinutes: 60,
      imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=500&q=80',
    ),
    const DestinationRecord(
      id: 'fb-071', name: 'Leticia by the Sea', location: 'Talikud Island, Samal',
      lat: 6.9410, lng: 125.7180, category: 'Hotel', rating: 4.3,
      status: 'active', isVerified: true,
      description: 'A seaside hotel with comfortable rooms, a restaurant, and beach access.',
      entranceFee: 0, averageStayMinutes: 60,
      imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=500&q=80',
    ),
    // ── Forest / Nature ────────────────────────────────────────────
    const DestinationRecord(
      id: 'fb-080', name: 'Samal Zipline', location: 'Peñaplata, Samal',
      lat: 7.0450, lng: 125.7050, category: 'Forest', rating: 4.4,
      status: 'active', isVerified: true,
      description: 'A thrilling zipline experience across a forest canopy with island views.',
      entranceFee: 300, averageStayMinutes: 60,
      imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=500&q=80',
    ),
  ];
}
