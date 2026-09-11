import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/palette.dart';
import '../../models/review.dart';
import '../../models/destination_record.dart';
import '../../services/destination_service.dart';

typedef _P = AppPalette;

// ── Place Data Model ─────────────────────────────────────────────────
class Place {
  final String name;
  final String location;
  final double rating;
  final String category; // Beach, Resort, Falls, Forest, Mountain, Island, Historical, Hotel
  final List<Color> gradient;
  final String description;
  final String price;
  final String owner;
  final String imageUrl;
  final List<String> galleryUrls;
  bool isLiked;

  Place({
    required this.name,
    required this.location,
    required this.rating,
    required this.category,
    required this.gradient,
    required this.description,
    required this.price,
    required this.owner,
    required this.imageUrl,
    this.galleryUrls = const [],
    this.isLiked = false,
  });

  factory Place.fromRecord(DestinationRecord rec) {
    List<Color> grad;
    switch (rec.category) {
      case 'Beach':
        grad = const [_P.skyBlue, _P.navy];
        break;
      case 'Falls':
      case 'Forest':
        grad = const [_P.blue, _P.navy];
        break;
      case 'Mountain':
        grad = const [_P.navy, _P.deepNavy];
        break;
      case 'Resort':
        grad = const [_P.skyBlue, _P.blue];
        break;
      case 'Island':
        grad = const [_P.skyBlue, _P.deepNavy];
        break;
      case 'Historical':
        grad = const [_P.navy, _P.deepNavy];
        break;
      case 'Hotel':
        grad = const [_P.skyBlue, _P.deepNavy];
        break;
      default:
        grad = const [_P.blue, _P.deepNavy];
    }

    return Place(
      name: rec.name,
      location: rec.location,
      rating: rec.rating,
      category: rec.category,
      gradient: grad,
      description: rec.description != null && rec.description!.isNotEmpty
          ? rec.description!
          : 'A verified destination in Samal Island with stunning views and local hospitality.',
      price: rec.formattedPrice,
      owner: rec.ownerName ?? 'Samal Tourism Board',
      imageUrl: rec.primaryImageUrl,
      galleryUrls: rec.galleryUrls,
      isLiked: false,
    );
  }
}

// ── All Samal Island Destinations ────────────────────────────────────
List<Place> _allPlaces() => [
  // ── Beach ──
  Place(
    name: 'Isla Reta Beach',
    location: 'Talikud Island, Samal',
    rating: 4.8,
    category: 'Beach',
    gradient: const [_P.blue, _P.deepNavy],
    description:
        'Crystal-clear waters and powdery white sand surrounded by lush coconut trees.',
    price: '₱150 entrance',
    owner: 'Isla Reta Resort Management',
    imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80',
    galleryUrls: [
      'https://images.unsplash.com/photo-1559494007-9f5847c49d94?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1520454974749-611b7248ffdb?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?auto=format&fit=crop&w=400&q=80',
    ],
    isLiked: true,
  ),
  Place(
    name: 'Kaputian Beach',
    location: 'South Samal',
    rating: 4.9,
    category: 'Beach',
    gradient: const [_P.skyBlue, _P.navy],
    description:
        'A long stretch of fine white sand with calm, shallow waters perfect for families.',
    price: '₱100 entrance',
    owner: 'Local Government Unit (LGU)',
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
  ),
  Place(
    name: 'Canibad Beach',
    location: 'Babak District',
    rating: 4.6,
    category: 'Beach',
    gradient: const [_P.skyBlue, _P.blue],
    description:
        'Hidden cove with turquoise water, great for cliff diving and snorkeling.',
    price: '₱80 entrance',
    owner: 'Canibad Tourism Coop',
    imageUrl: 'https://images.unsplash.com/photo-1439066615861-d1af74d74000?auto=format&fit=crop&w=600&q=80',
    galleryUrls: [
      'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1468413253725-0d5181091126?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1484821582734-6c6c9a0e1bda?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  Place(
    name: 'Paradise Island',
    location: 'Penaplata, Samal',
    rating: 4.7,
    category: 'Beach',
    gradient: const [_P.skyBlue, _P.navy],
    description:
        'Resort island with water sports, swimming pools, and beachfront cottages.',
    price: '₱250 day pass',
    owner: 'Paradise Island Park & Beach Resort',
    imageUrl: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=600&q=80',
  ),

  // ── Forest ──
  Place(
    name: 'Hagimit Falls',
    location: 'Cawag, Samal',
    rating: 4.7,
    category: 'Forest',
    gradient: const [_P.blue, _P.navy],
    description:
        'Multi-tiered waterfall hidden in a lush tropical forest with natural rock pools.',
    price: '₱50 entrance',
    owner: 'Samal Ecotourism Board',
    imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=600&q=80',
  ),
  Place(
    name: 'Maxima Aquafun',
    location: 'Babak District',
    rating: 4.5,
    category: 'Forest',
    gradient: const [_P.skyBlue, _P.blue],
    description:
        'Nature park with zip lines, hanging bridges, and forest trails.',
    price: '₱350 all-access',
    owner: 'Maxima Resort Group',
    imageUrl: 'https://images.unsplash.com/photo-1538964173425-93884d739596?auto=format&fit=crop&w=600&q=80',
    galleryUrls: [
      'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=400&q=80',
    ],
  ),
  Place(
    name: 'Ligid Cave',
    location: 'San Antonio, Samal',
    rating: 4.3,
    category: 'Forest',
    gradient: const [_P.skyBlue, _P.deepNavy],
    description:
        'Mysterious cave system inside a dense forest. Bring a guide and flashlight.',
    price: '₱100 guided tour',
    owner: 'San Antonio Local Guides',
    imageUrl: 'https://images.unsplash.com/photo-1507163546605-a84d8ff1a3bb?auto=format&fit=crop&w=600&q=80',
  ),

  // ── Mountain ──
  Place(
    name: 'Mt. Puting Bato',
    location: 'Peñaplata, Samal',
    rating: 4.6,
    category: 'Mountain',
    gradient: const [_P.navy, _P.deepNavy],
    description:
        'A scenic hilltop with panoramic views of the Davao Gulf at sunrise.',
    price: 'Free (guide tip)',
    owner: 'Peñaplata Tourism Council',
    imageUrl: 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=600&q=80',
  ),
  Place(
    name: 'Bali-Bali View Deck',
    location: 'Babak District',
    rating: 4.4,
    category: 'Mountain',
    gradient: const [_P.blue, _P.navy],
    description:
        'Mountain view deck overlooking the sea, perfect for sunset watching.',
    price: '₱30 entrance',
    owner: 'Bali-Bali Enterprises',
    imageUrl: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=600&q=80',
  ),

  // ── Island ──
  Place(
    name: 'Talikud Island',
    location: 'South of Samal',
    rating: 4.9,
    category: 'Island',
    gradient: const [_P.skyBlue, _P.deepNavy],
    description:
        'Secluded island paradise with pristine coral reefs and untouched beaches.',
    price: '₱200 boat ride',
    owner: 'Talikud LGU & Maritime',
    imageUrl: 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=600&q=80',
  ),
  Place(
    name: 'Vanishing Island',
    location: 'Samal Strait',
    rating: 4.8,
    category: 'Island',
    gradient: const [_P.skyBlue, _P.navy],
    description:
        'A sandbar that appears only during low tide — a truly magical experience.',
    price: '₱300 boat tour',
    owner: 'Samal Boat Operators Assoc.',
    imageUrl: 'https://images.unsplash.com/photo-1473116763269-255448993f66?auto=format&fit=crop&w=600&q=80',
  ),
  Place(
    name: 'Coral Garden',
    location: 'Talikud Island',
    rating: 4.7,
    category: 'Island',
    gradient: const [_P.skyBlue, _P.blue],
    description:
        'Underwater paradise with vibrant coral formations and tropical fish.',
    price: '₱500 snorkel tour',
    owner: 'Talikud Marine Sanctuary',
    imageUrl: 'https://images.unsplash.com/photo-1546026423-cc4642628d2b?auto=format&fit=crop&w=600&q=80',
  ),
];

// ── Notification Data ────────────────────────────────────────────────
class _Notif {
  final String title;
  final String body;
  final String time;
  final IconData icon;

  const _Notif(this.title, this.body, this.time, this.icon);
}

const _notifications = [
  _Notif(
    'Welcome to SamalNav!',
    'Start exploring the best spots on Samal Island.',
    'Just now',
    Icons.waving_hand_rounded,
  ),
  _Notif(
    'New: Island Hopping Package',
    '3-day island hopping is now available for ₱4,500/person.',
    '2h ago',
    Icons.card_travel_rounded,
  ),
  _Notif(
    'Weekend Deal',
    'Get 20% off Isla Reta entrance this Saturday!',
    '5h ago',
    Icons.local_offer_rounded,
  ),
  _Notif(
    'Tide Alert',
    'Vanishing Island will appear tomorrow 6AM – 10AM.',
    '1d ago',
    Icons.water_rounded,
  ),
];

// ═════════════════════════════════════════════════════════════════════
//  HOME PAGE
// ═════════════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Beach';
  late List<Place> _places;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  final _categories = [
    {'name': 'Beach', 'icon': Icons.beach_access_rounded},
    {'name': 'Resort', 'icon': Icons.villa_rounded},
    {'name': 'Falls', 'icon': Icons.water_drop_rounded},
    {'name': 'Mountain', 'icon': Icons.landscape_rounded},
    {'name': 'Island', 'icon': Icons.water_rounded},
    {'name': 'Historical', 'icon': Icons.account_balance_rounded},
    {'name': 'Hotel', 'icon': Icons.hotel_rounded},
    {'name': 'Forest', 'icon': Icons.park_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _places = _allPlaces();
    _loadPlaces();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  Future<void> _loadPlaces() async {
    try {
      final records = await DestinationService.getAll();
      if (mounted && records.isNotEmpty) {
        setState(() {
          _places = records.map((r) => Place.fromRecord(r)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading places in HomePage: $e');
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Place> get _filteredByCategory =>
      _places.where((p) => p.category == _selectedCategory).toList();

  List<Place> get _favoritePlaces => _places.where((p) => p.isLiked).toList();

  List<Place> get _popularPlaces {
    final sorted = List<Place>.from(_places)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  }

  List<Place> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    return _places
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchQuery) ||
              p.location.toLowerCase().contains(_searchQuery) ||
              p.category.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  void _toggleFavorite(Place place) {
    setState(() => place.isLiked = !place.isLiked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          place.isLiked
              ? 'Added ${place.name} to favorites'
              : 'Removed ${place.name} from favorites',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _P.deepNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: const BoxDecoration(
              color: _P.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          color: _P.deepNavy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '4 new',
                        style: TextStyle(
                          color: _P.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: i == 0 ? _P.iceBlue : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: i == 0 ? _P.blue : _P.iceBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                n.icon,
                                color: i == 0 ? Colors.white : _P.deepNavy,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: const TextStyle(
                                      color: _P.deepNavy,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.body,
                                    style: const TextStyle(
                                      color: _P.inkSoft,
                                      fontSize: 12.5,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    n.time,
                                    style: TextStyle(
                                      color: _P.inkSoft.withValues(alpha: 0.6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceDetail(Place place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          decoration: const BoxDecoration(
            color: _P.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle inside the container
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero gradient card
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(place.imageUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.25),
                            BlendMode.srcOver,
                          ),
                        ),
                        gradient: LinearGradient(
                          colors: place.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -30,
                            right: -30,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            left: -20,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.04),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      place.location,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFA726),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    getAverageRating(
                                      place.name,
                                      place.rating,
                                    ).toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: _P.deepNavy,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Heart / Favorite Button inside Header Container
                          Positioned(
                            top: 16,
                            left: 16,
                            child: GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  _toggleFavorite(place);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: place.isLiked
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  place.isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: place.isLiked ? Colors.redAccent : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _P.iceBlue,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      place.category,
                      style: const TextStyle(
                        color: _P.deepNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'About this spot',
                    style: TextStyle(
                      color: _P.deepNavy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.description,
                    style: const TextStyle(
                      color: _P.inkSoft,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── Photo Gallery ──
                  if (place.galleryUrls.isNotEmpty) ...[
                    const Text(
                      'Photos',
                      style: TextStyle(
                        color: _P.deepNavy,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: place.galleryUrls.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            place.galleryUrls[i],
                            width: 140,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 140,
                              height: 100,
                              color: _P.iceBlue,
                              child: const Icon(Icons.image_rounded, color: _P.inkSoft),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _P.iceBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          color: _P.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Owner: ${place.owner}',
                            style: const TextStyle(
                              color: _P.deepNavy,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Price + Book row
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(
                              color: _P.inkSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            place.price,
                            style: const TextStyle(
                              color: _P.deepNavy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushReplacementNamed(
                            '/plan',
                            arguments: {'destination': place.name},
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _P.blue,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.route_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Add to Plan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // ── Ratings and Reviews Section ──
                  _buildRatingSummary(place.name, place.rating),
                  const SizedBox(height: 20),
                  // ── Rate This Spot ──
                  _buildRateThisSpot(place.name),
                  const SizedBox(height: 20),
                  // ── Reviews List ──
                  _buildReviewsSection(place.name),
                  const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [_P.blue, _P.skyBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: _P.white,
                            child: Icon(
                              Icons.person_rounded,
                              color: _P.deepNavy,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting().toUpperCase(),
                              style: const TextStyle(
                                color: _P.inkSoft,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Hello, Explorer',
                              style: TextStyle(
                                color: _P.deepNavy,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showNotifications,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _P.deepNavy.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: _P.deepNavy,
                              size: 22,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: _P.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Title ──────────────────────────────────────────────
                const Text(
                  'Where do you want\nto explore today?',
                  style: TextStyle(
                    color: _P.deepNavy,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 22),

                // ── Weather Container ──────────────────────────────────
                _buildWeatherCard(),
                const SizedBox(height: 20),

                // ── Search Bar ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _P.deepNavy.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(
                            color: _P.deepNavy,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search beaches, forests, islands…',
                            hintStyle: TextStyle(
                              color: _P.inkSoft.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            isCollapsed: true,
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => _searchCtrl.clear(),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: _P.inkSoft,
                                      size: 18,
                                    ),
                                  )
                                : null,
                            suffixIconConstraints: const BoxConstraints(
                              maxHeight: 20,
                              maxWidth: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: _P.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ── Search Results ─────────────────────────────────────
                if (isSearching) ...[
                  Text(
                    'Results for "$_searchQuery"',
                    style: const TextStyle(
                      color: _P.deepNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_searchResults.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: _P.iceBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            color: _P.inkSoft,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No places found for "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _P.inkSoft,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 270,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (_, i) => _buildBigCard(_searchResults[i]),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],

                // ── Categories ─────────────────────────────────────────
                if (!isSearching) ...[
                  _sectionHeader('Choose Category', ''),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: _categories.map((cat) {
                        final name = cat['name'] as String;
                        final icon = cat['icon'] as IconData;
                        final selected = _selectedCategory == name;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? _P.deepNavy : Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: _P.deepNavy.withValues(
                                      alpha: selected ? 0.18 : 0.04,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : _P.iceBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      icon,
                                      color: selected
                                          ? _P.skyBlue
                                          : _P.deepNavy,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : _P.deepNavy,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Recommended Places',
                    style: TextStyle(
                      color: _P.deepNavy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Category Results (horizontal cards) ──────────────
                  SizedBox(
                    height: 270,
                    child: _filteredByCategory.isEmpty
                        ? Center(
                            child: Text(
                              'No ${_selectedCategory.toLowerCase()} spots yet',
                              style: const TextStyle(
                                color: _P.inkSoft,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: _filteredByCategory.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 16),
                            itemBuilder: (_, i) =>
                                _buildBigCard(_filteredByCategory[i]),
                          ),
                  ),
                  const SizedBox(height: 34),

                  // ── Favorite Places ──────────────────────────────────
                  _sectionHeaderWithIcon(
                    'Favorite Places',
                    Icons.favorite_rounded,
                    Colors.redAccent,
                    '${_favoritePlaces.length} saved',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Navigating to all favorites...',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: _P.deepNavy,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_favoritePlaces.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: _P.iceBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            color: _P.inkSoft,
                            size: 36,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No favorites yet!',
                            style: TextStyle(
                              color: _P.deepNavy,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap the heart on any place to save it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _P.inkSoft, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: _favoritePlaces.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) =>
                            _buildFavChip(_favoritePlaces[i]),
                      ),
                    ),
                  const SizedBox(height: 34),

                  // ── Popular Places ───────────────────────────────────
                  _sectionHeaderWithIcon(
                    'Popular in Samal',
                    Icons.local_fire_department_rounded,
                    _P.blue,
                    'Top rated',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Viewing top rated places...',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: _P.blue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 270,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: _popularPlaces.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (_, i) => _buildBigCard(_popularPlaces[i]),
                    ),
                  ),
                  const SizedBox(height: 34),

                  // ── Popular Packages ─────────────────────────────────
                  _sectionHeader(
                    'Popular Packages',
                    'See all',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Viewing all packages...',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: _P.navy,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _packageCard(
                    'Island Hopping, 3 Days',
                    'Samal · Talikud · Eden',
                    '₱4,500 / person',
                    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=300&q=80',
                  ),
                  const SizedBox(height: 12),
                  _packageCard(
                    'Forest Trek & Falls',
                    'Hagimit · Maxima · Ligid',
                    '₱2,800 / person',
                    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=300&q=80',
                  ),
                  const SizedBox(height: 12),
                  _packageCard(
                    'Sunset Mountain Tour',
                    'Mt. Puting Bato · Bali-Bali',
                    '₱1,500 / person',
                    'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=300&q=80',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CARD WIDGETS
  // ═══════════════════════════════════════════════════════════════════

  // Big vertical card (for category browsing)
  Widget _buildBigCard(Place place) {
    return GestureDetector(
      onTap: () => _showPlaceDetail(place),
      child: Container(
          width: 200,
          height: 260,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(place.imageUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.25),
                BlendMode.srcOver,
              ),
            ),
            gradient: LinearGradient(
              colors: place.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: place.gradient[1].withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),

              // Heart
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(place),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: place.isLiked
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      place.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: place.isLiked ? Colors.redAccent : Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ),
              // Rating
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFA726),
                        size: 14,
                      ),
                      Text(
                        getAverageRating(
                          place.name,
                          place.rating,
                        ).toStringAsFixed(1),
                        style: const TextStyle(
                          color: _P.deepNavy,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Details
              Positioned(
                bottom: 18,
                left: 18,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white70,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
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

  // Small horizontal favorite chip
  Widget _buildFavChip(Place place) {
    return GestureDetector(
      onTap: () => _showPlaceDetail(place),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(place.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.25),
              BlendMode.srcOver,
            ),
          ),
          gradient: LinearGradient(
            colors: place.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: place.gradient[1].withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleFavorite(place),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white60,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    place.location,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFA726),
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  getAverageRating(place.name, place.rating).toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WEATHER CARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildWeatherCard() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayName = days[_now.weekday - 1];
    final dateStr = '${months[_now.month - 1]} ${_now.day}, ${_now.year}';
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final amPm = _now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute:$second $amPm';

    // Simulated weather based on time of day
    final isNight = _now.hour < 6 || _now.hour >= 18;
    final weatherIcon = isNight
        ? Icons.nights_stay_rounded
        : Icons.wb_sunny_rounded;
    final weatherLabel = isNight ? 'Clear Night' : 'Partly Sunny';
    final temp = isNight ? '26' : '32';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_P.navy, _P.deepNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _P.deepNavy.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: date, time, location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: _P.skyBlue,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$dayName, $dateStr',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: _P.skyBlue,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Samal Island, Davao',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right side: weather
              Column(
                children: [
                  Icon(
                    weatherIcon,
                    color: isNight ? _P.skyBlue : const Color(0xFFFFA726),
                    size: 40,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$temp\u00B0C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weatherLabel,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Widget _sectionHeader(String title, String action, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _P.deepNavy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                color: _P.blue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeaderWithIcon(
    String title,
    IconData icon,
    Color iconColor,
    String action, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _P.deepNavy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                color: _P.blue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _packageCard(
    String title,
    String subtitle,
    String price,
    String imageUrl,
  ) {
    return GestureDetector(
      onTap: () => _showPackageDetailSheet(title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _P.deepNavy.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 64,
                  height: 64,
                  color: _P.iceBlue,
                  child: const Icon(Icons.image_rounded, color: _P.inkSoft),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _P.deepNavy,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _P.inkSoft,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    price,
                    style: const TextStyle(
                      color: _P.navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushReplacementNamed(
                '/plan',
                arguments: {'package': title},
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _P.iceBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: _P.deepNavy,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PACKAGE DETAIL SHEET — itinerary preview with resort photos
  // ═══════════════════════════════════════════════════════════════════

  void _showPackageDetailSheet(String title) {
    // ── Package data ──
    String distance;
    String totalTime;
    int stopsCount;
    final Map<String, List<Map<String, String>>> days = {};

    if (title.contains('Island Hopping')) {
      distance = '24.5 km';
      totalTime = '8.5 hrs';
      stopsCount = 4;
      days['Day 1'] = [
        {'name': 'Kaputian Beach', 'location': 'South Samal', 'time': '9:00 AM', 'duration': '2.5h', 'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=300&q=80', 'transit': '12.8 km · 25 min'},
        {'name': 'Talikud Island', 'location': 'Kaputian District', 'time': '12:00 PM', 'duration': '3.0h', 'image': 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=300&q=80'},
      ];
      days['Day 2'] = [
        {'name': 'Vanishing Island', 'location': 'Babak District', 'time': '10:00 AM', 'duration': '3.0h', 'image': 'https://images.unsplash.com/photo-1473116763269-255448993f66?auto=format&fit=crop&w=300&q=80'},
      ];
      days['Day 3'] = [
        {'name': 'Pearl Farm Resort', 'location': 'Kaputian, Samal', 'time': '11:00 AM', 'duration': '4.0h', 'image': 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=300&q=80'},
      ];
    } else if (title.contains('Forest Trek')) {
      distance = '18.2 km';
      totalTime = '5.5 hrs';
      stopsCount = 3;
      days['Day 1'] = [
        {'name': 'Hagimit Falls', 'location': 'Penaplata, Samal', 'time': '8:30 AM', 'duration': '2.0h', 'image': 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=300&q=80', 'transit': '4.5 km · 12 min'},
        {'name': 'Maxima Aquafun', 'location': 'Penaplata, Samal', 'time': '10:42 AM', 'duration': '2.0h', 'image': 'https://images.unsplash.com/photo-1538964173425-93884d739596?auto=format&fit=crop&w=300&q=80', 'transit': '13.7 km · 28 min'},
        {'name': 'Ligid Island Cave', 'location': 'Penaplata, Samal', 'time': '1:30 PM', 'duration': '1.5h', 'image': 'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?auto=format&fit=crop&w=300&q=80'},
      ];
    } else {
      distance = '11.3 km';
      totalTime = '4.0 hrs';
      stopsCount = 2;
      days['Day 1'] = [
        {'name': 'Mt. Puting Bato', 'location': 'Bali-Bali, Samal', 'time': '3:00 PM', 'duration': '2.5h', 'image': 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=300&q=80', 'transit': '5.1 km · 14 min'},
        {'name': 'Bali-Bali View Deck', 'location': 'Penaplata, Samal', 'time': '5:45 PM', 'duration': '1.5h', 'image': 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=300&q=80'},
      ];
    }

    final now = DateTime.now();
    final dateStr = '${_monthName(now.month)} ${now.day}, ${now.year}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: _P.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_P.deepNavy, _P.navy],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Optimized by MOGA',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(dateStr,
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _statColumn(Icons.straighten_rounded, distance, 'Distance'),
                              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
                              _statColumn(Icons.schedule_rounded, totalTime, 'Total time'),
                              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
                              _statColumn(Icons.location_on_rounded, '$stopsCount', 'Stops'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Route order header ──
                    Row(
                      children: [
                        Container(width: 4, height: 22, decoration: BoxDecoration(color: _P.blue, borderRadius: BorderRadius.circular(50))),
                        const SizedBox(width: 10),
                        const Text('Route order', style: TextStyle(color: _P.deepNavy, fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Text('Stop-by-stop, in the order MOGA recommends.',
                          style: TextStyle(color: _P.inkSoft, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 20),

                    // ── Day-grouped timeline ──
                    ...days.entries.expand((dayEntry) {
                      final dayLabel = dayEntry.key;
                      final stops = dayEntry.value;
                      return [
                        if (days.length > 1) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _P.iceBlue,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(dayLabel,
                                style: const TextStyle(color: _P.deepNavy, fontSize: 12, fontWeight: FontWeight.w800)),
                          ),
                        ],
                        ...stops.asMap().entries.map((e) {
                          final idx = e.key;
                          final stop = e.value;
                          final isLast = idx == stops.length - 1;
                          final transit = stop['transit'];
                          return _buildTimelineStop(stop, isLast && (dayEntry.key == days.keys.last), transit);
                        }),
                      ];
                    }),

                    const SizedBox(height: 24),

                    // ── Action button ──
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushReplacementNamed(
                          '/plan',
                          arguments: {'package': title},
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_P.blue, Color(0xFF1E88E5)]),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(color: _P.blue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.route_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text('Open in Planner',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  Widget _statColumn(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTimelineStop(Map<String, String> stop, bool isLastStop, String? transit) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: photo + timeline line
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.network(
                    stop['image'] ?? '',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => CircleAvatar(
                      radius: 21,
                      backgroundColor: _P.iceBlue,
                      child: const Icon(Icons.image_rounded, color: _P.blue, size: 18),
                    ),
                  ),
                ),
                if (!isLastStop)
                  Container(
                    width: 3,
                    height: transit != null ? 44 : 16,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: _P.iceBlue,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Right: info card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _P.iceBlue.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stop['name'] ?? '',
                              style: const TextStyle(color: _P.deepNavy, fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: _P.navy, size: 12),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(stop['location'] ?? '',
                                    style: const TextStyle(color: _P.inkSoft, fontSize: 11.5, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, color: _P.blue, size: 13),
                          const SizedBox(width: 4),
                          Text(stop['duration'] ?? '',
                              style: const TextStyle(color: _P.deepNavy, fontSize: 11, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Transit row
        if (transit != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: _P.iceBlue, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car_rounded, color: _P.blue, size: 13),
                  const SizedBox(width: 6),
                  Text(transit,
                      style: const TextStyle(color: _P.inkSoft, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
        if (!isLastStop && transit == null) const SizedBox(height: 8),
      ],
    );
  }

  // ignore: unused_element
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Beach':
        return Icons.beach_access_rounded;
      case 'Forest':
        return Icons.park_rounded;
      case 'Mountain':
        return Icons.landscape_rounded;
      case 'Island':
        return Icons.water_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  // ── Rating Summary (Google Play Store Style) ──
  Widget _buildRatingSummary(String placeName, double defaultRating) {
    final reviews = globalReviews[placeName] ?? [];
    final avgRating = getAverageRating(placeName, defaultRating);
    final totalReviews = reviews.length;

    // Count per star
    final Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in reviews) {
      final s = r.rating.round().clamp(1, 5);
      starCounts[s] = (starCounts[s] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ratings and reviews',
              style: TextStyle(
                color: _P.deepNavy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              onPressed: () => _showWriteReviewSheet(placeName),
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: _P.blue,
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _P.iceBlue,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No reviews yet. Be the first to review!',
                style: TextStyle(color: _P.inkSoft, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big average number
              Column(
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: _P.deepNavy,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = avgRating - i;
                      return Icon(
                        filled >= 0.75
                            ? Icons.star_rounded
                            : filled >= 0.25
                                ? Icons.star_half_rounded
                                : Icons.star_border_rounded,
                        color: _P.blue,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalReviews reviews',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Star breakdown bars
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final count = starCounts[star] ?? 0;
                    final pct = totalReviews > 0 ? count / totalReviews : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12,
                            child: Text(
                              '$star',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  _P.blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Rate This Spot Section ──
  Widget _buildRateThisSpot(String placeName) {
    final reviews = globalReviews[placeName] ?? [];
    final myReviews = reviews.where((r) => r.authorName == 'You').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              const Text(
                'Rate this spot',
                style: TextStyle(
                  color: _P.deepNavy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tell others what you think',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => _showWriteReviewSheet(placeName, initialRating: i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.star_border_rounded,
                        color: Colors.grey.shade400,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        if (myReviews.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Your review history',
            style: TextStyle(
              color: _P.deepNavy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: myReviews.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final r = myReviews[idx];
              final diff = DateTime.now().difference(r.date);
              String dateStr = '${r.date.day}/${r.date.month}/${r.date.year}';
              if (diff.inDays == 0) dateStr = 'Today';
              if (diff.inDays == 1) dateStr = 'Yesterday';
              if (diff.inDays > 1 && diff.inDays < 30) dateStr = '${diff.inDays} days ago';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _P.iceBlue.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < r.rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: _P.blue,
                              size: 14,
                            );
                          }),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.comment,
                      style: const TextStyle(
                        color: _P.deepNavy,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // ── Reviews List (Individual review cards with helpful buttons) ──
  Widget _buildReviewsSection(String placeName) {
    final reviews = globalReviews[placeName] ?? [];
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          itemBuilder: (context, index) {
            final r = reviews[index];
            // Format date
            final diff = DateTime.now().difference(r.date);
            String dateStr;
            if (diff.inDays == 0) {
              dateStr = 'Today';
            } else if (diff.inDays == 1) {
              dateStr = 'Yesterday';
            } else if (diff.inDays < 30) {
              dateStr = '${diff.inDays} days ago';
            } else if (diff.inDays < 365) {
              final months = (diff.inDays / 30).floor();
              dateStr = '$months month${months > 1 ? 's' : ''} ago';
            } else {
              dateStr = '${r.date.day}/${r.date.month}/${r.date.year}';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row with avatar
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _P.blue.withValues(alpha: 0.15),
                      child: Text(
                        r.authorName[0].toUpperCase(),
                        style: const TextStyle(
                          color: _P.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      r.authorName,
                      style: const TextStyle(
                        color: _P.deepNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Stars + Date
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < r.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _P.blue,
                        size: 14,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Comment
                Text(
                  r.comment,
                  style: const TextStyle(
                    color: _P.inkSoft,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                // Helpful section
                Row(
                  children: [
                    Text(
                      'Was this review helpful?',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _helpfulButton(
                      label: 'Yes',
                      count: r.helpfulYes,
                      icon: Icons.thumb_up_alt_outlined,
                      onTap: () {
                        setState(() => r.helpfulYes++);
                      },
                    ),
                    const SizedBox(width: 8),
                    _helpfulButton(
                      label: 'No',
                      count: r.helpfulNo,
                      icon: Icons.thumb_down_alt_outlined,
                      onTap: () {
                        setState(() => r.helpfulNo++);
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _helpfulButton({
    required String label,
    required int count,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWriteReviewSheet(String placeName, {int initialRating = 5}) {
    int selectedRating = initialRating;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Write a Review',
                      style: TextStyle(
                        color: _P.deepNavy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Rating',
                      style: TextStyle(
                        color: _P.inkSoft,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () =>
                              setSheetState(() => selectedRating = index + 1),
                          icon: Icon(
                            index < selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: index < selectedRating
                                ? _P.blue
                                : Colors.grey.shade300,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Comment',
                      style: TextStyle(
                        color: _P.inkSoft,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        hintStyle: const TextStyle(color: _P.inkSoft),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _P.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (textController.text.trim().isEmpty) return;

                          final newReview = Review(
                            authorName: 'You',
                            rating: selectedRating.toDouble(),
                            comment: textController.text.trim(),
                            date: DateTime.now(),
                          );

                          setState(() {
                            if (globalReviews.containsKey(placeName)) {
                              globalReviews[placeName]!.insert(0, newReview);
                            } else {
                              globalReviews[placeName] = [newReview];
                            }
                          });

                          Navigator.pop(ctx); // close review sheet
                          Navigator.pop(
                            context,
                          ); // close details sheet so user can reopen and see it fresh
                          _showPlaceDetail(
                            _places.firstWhere(
                              (p) => p.name == placeName,
                              orElse: () => _places.first,
                            ),
                          );
                        },
                        child: const Text(
                          'Submit Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}


