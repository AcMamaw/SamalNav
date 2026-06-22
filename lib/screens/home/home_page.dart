import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/palette.dart';

typedef _P = AppPalette;

// ── Place Data Model ─────────────────────────────────────────────────
class Place {
  final String name;
  final String location;
  final double rating;
  final String category; // Beach, Forest, Mountain, Island
  final List<Color> gradient;
  final String description;
  final String price;
  final String owner;
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
    this.isLiked = false,
  });
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
    description: 'Crystal-clear waters and powdery white sand surrounded by lush coconut trees.',
    price: '₱150 entrance',
    owner: 'Isla Reta Resort Management',
    isLiked: true,
  ),
  Place(
    name: 'Kaputian Beach',
    location: 'South Samal',
    rating: 4.9,
    category: 'Beach',
    gradient: const [_P.skyBlue, _P.navy],
    description: 'A long stretch of fine white sand with calm, shallow waters perfect for families.',
    price: '₱100 entrance',
    owner: 'Local Government Unit (LGU)',
  ),
  Place(
    name: 'Canibad Beach',
    location: 'Babak District',
    rating: 4.6,
    category: 'Beach',
    gradient: const [_P.skyBlue, _P.blue],
    description: 'Hidden cove with turquoise water, great for cliff diving and snorkeling.',
    price: '₱80 entrance',
    owner: 'Canibad Tourism Coop',
  ),
  Place(
    name: 'Paradise Island',
    location: 'Penaplata, Samal',
    rating: 4.7,
    category: 'Beach',
    gradient: const [_P.skyBlue, _P.navy],
    description: 'Resort island with water sports, swimming pools, and beachfront cottages.',
    price: '₱250 day pass',
    owner: 'Paradise Island Park & Beach Resort',
  ),

  // ── Forest ──
  Place(
    name: 'Hagimit Falls',
    location: 'Cawag, Samal',
    rating: 4.7,
    category: 'Forest',
    gradient: const [_P.blue, _P.navy],
    description: 'Multi-tiered waterfall hidden in a lush tropical forest with natural rock pools.',
    price: '₱50 entrance',
    owner: 'Samal Ecotourism Board',
  ),
  Place(
    name: 'Maxima Aquafun',
    location: 'Babak District',
    rating: 4.5,
    category: 'Forest',
    gradient: const [_P.skyBlue, _P.blue],
    description: 'Nature park with zip lines, hanging bridges, and forest trails.',
    price: '₱350 all-access',
    owner: 'Maxima Resort Group',
  ),
  Place(
    name: 'Ligid Cave',
    location: 'San Antonio, Samal',
    rating: 4.3,
    category: 'Forest',
    gradient: const [_P.skyBlue, _P.deepNavy],
    description: 'Mysterious cave system inside a dense forest. Bring a guide and flashlight.',
    price: '₱100 guided tour',
    owner: 'San Antonio Local Guides',
  ),

  // ── Mountain ──
  Place(
    name: 'Mt. Puting Bato',
    location: 'Peñaplata, Samal',
    rating: 4.6,
    category: 'Mountain',
    gradient: const [_P.navy, _P.deepNavy],
    description: 'A scenic hilltop with panoramic views of the Davao Gulf at sunrise.',
    price: 'Free (guide tip)',
    owner: 'Peñaplata Tourism Council',
  ),
  Place(
    name: 'Bali-Bali View Deck',
    location: 'Babak District',
    rating: 4.4,
    category: 'Mountain',
    gradient: const [_P.blue, _P.navy],
    description: 'Mountain view deck overlooking the sea, perfect for sunset watching.',
    price: '₱30 entrance',
    owner: 'Bali-Bali Enterprises',
  ),

  // ── Island ──
  Place(
    name: 'Talikud Island',
    location: 'South of Samal',
    rating: 4.9,
    category: 'Island',
    gradient: const [_P.skyBlue, _P.deepNavy],
    description: 'Secluded island paradise with pristine coral reefs and untouched beaches.',
    price: '₱200 boat ride',
    owner: 'Talikud LGU & Maritime',
  ),
  Place(
    name: 'Vanishing Island',
    location: 'Samal Strait',
    rating: 4.8,
    category: 'Island',
    gradient: const [_P.skyBlue, _P.navy],
    description: 'A sandbar that appears only during low tide — a truly magical experience.',
    price: '₱300 boat tour',
    owner: 'Samal Boat Operators Assoc.',
  ),
  Place(
    name: 'Coral Garden',
    location: 'Talikud Island',
    rating: 4.7,
    category: 'Island',
    gradient: const [_P.skyBlue, _P.blue],
    description: 'Underwater paradise with vibrant coral formations and tropical fish.',
    price: '₱500 snorkel tour',
    owner: 'Talikud Marine Sanctuary',
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
  _Notif('Welcome to SamalNav!', 'Start exploring the best spots on Samal Island.', 'Just now', Icons.waving_hand_rounded),
  _Notif('New: Island Hopping Package', '3-day island hopping is now available for ₱4,500/person.', '2h ago', Icons.card_travel_rounded),
  _Notif('Weekend Deal', 'Get 20% off Isla Reta entrance this Saturday!', '5h ago', Icons.local_offer_rounded),
  _Notif('Tide Alert', 'Vanishing Island will appear tomorrow 6AM – 10AM.', '1d ago', Icons.water_rounded),
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
    {'name': 'Forest', 'icon': Icons.park_rounded},
    {'name': 'Mountain', 'icon': Icons.landscape_rounded},
    {'name': 'Island', 'icon': Icons.water_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _places = _allPlaces();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Place> get _filteredByCategory =>
      _places.where((p) => p.category == _selectedCategory).toList();

  List<Place> get _favoritePlaces =>
      _places.where((p) => p.isLiked).toList();

  List<Place> get _popularPlaces {
    final sorted = List<Place>.from(_places)..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  }

  List<Place> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    return _places.where((p) =>
        p.name.toLowerCase().contains(_searchQuery) ||
        p.location.toLowerCase().contains(_searchQuery) ||
        p.category.toLowerCase().contains(_searchQuery)
    ).toList();
  }

  void _toggleFavorite(Place place) {
    setState(() => place.isLiked = !place.isLiked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          place.isLiked ? 'Added ${place.name} to favorites' : 'Removed ${place.name} from favorites',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50))),
          const SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
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
                  Text('Notifications', style: TextStyle(color: _P.deepNavy, fontSize: 20, fontWeight: FontWeight.w800)),
                  Spacer(),
                  Text('4 new', style: TextStyle(color: _P.blue, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                          child: Icon(n.icon, color: i == 0 ? Colors.white : _P.deepNavy, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: const TextStyle(color: _P.deepNavy, fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(n.body, style: const TextStyle(color: _P.inkSoft, fontSize: 12.5, height: 1.3)),
                              const SizedBox(height: 6),
                              Text(n.time, style: TextStyle(color: _P.inkSoft.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600)),
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
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50))),
          const SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            decoration: const BoxDecoration(
              color: _P.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero gradient card
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: place.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -30, right: -30, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
                    Positioned(bottom: -20, left: -20, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
                    Positioned(
                      bottom: 20, left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(place.location, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ]),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 16, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(50)),
                        child: Row(children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 16),
                          const SizedBox(width: 4),
                          Text(place.rating.toString(), style: const TextStyle(color: _P.deepNavy, fontSize: 13, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Category chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(50)),
                child: Text(place.category, style: const TextStyle(color: _P.deepNavy, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              const Text('About this spot', style: TextStyle(color: _P.deepNavy, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(place.description, style: const TextStyle(color: _P.inkSoft, fontSize: 14, height: 1.5)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: _P.blue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Owner: ${place.owner}', style: const TextStyle(color: _P.deepNavy, fontSize: 13, fontWeight: FontWeight.w700))),
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
                      const Text('Price', style: TextStyle(color: _P.inkSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(place.price, style: const TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Reservation request sent to ${place.owner}!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                            ],
                          ),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(color: _P.blue, borderRadius: BorderRadius.circular(50)),
                      child: const Text('Reserve Now', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
        ],
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
                        child: Icon(Icons.person_rounded, color: _P.deepNavy, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting().toUpperCase(),
                          style: const TextStyle(color: _P.inkSoft, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.4),
                        ),
                        const SizedBox(height: 2),
                        const Text('Hello, Explorer', style: TextStyle(color: _P.deepNavy, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
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
                      boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_none_rounded, color: _P.deepNavy, size: 22),
                        Positioned(
                          right: 0, top: 0,
                          child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: _P.blue, shape: BoxShape.circle)),
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
              style: TextStyle(color: _P.deepNavy, fontSize: 30, fontWeight: FontWeight.w800, height: 1.18, letterSpacing: -0.5),
            ),
            const SizedBox(height: 22),

            // ── Search Bar ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Search beaches, forests, islands…',
                        hintStyle: TextStyle(color: _P.inkSoft.withValues(alpha: 0.55), fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        isCollapsed: true,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () => _searchCtrl.clear(),
                                child: const Icon(Icons.close_rounded, color: _P.inkSoft, size: 18),
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints(maxHeight: 20, maxWidth: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: _P.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Weather Container ──────────────────────────────────
            _buildWeatherCard(),
            const SizedBox(height: 30),

            // ── Search Results ─────────────────────────────────────
            if (isSearching) ...[
              Text('Results for "$_searchQuery"',
                  style: const TextStyle(color: _P.deepNavy, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              if (_searchResults.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, color: _P.inkSoft, size: 40),
                      const SizedBox(height: 12),
                      Text('No places found for "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _P.inkSoft, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
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
                        onTap: () => setState(() => _selectedCategory = name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? _P.deepNavy : Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [BoxShadow(
                              color: _P.deepNavy.withValues(alpha: selected ? 0.18 : 0.04),
                              blurRadius: 12, offset: const Offset(0, 6),
                            )],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.white.withValues(alpha: 0.15) : _P.iceBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: selected ? _P.skyBlue : _P.deepNavy, size: 14),
                              ),
                              const SizedBox(width: 8),
                              Text(name, style: TextStyle(
                                color: selected ? Colors.white : _P.deepNavy,
                                fontWeight: FontWeight.w700, fontSize: 13.5,
                              )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // ── Category Results (horizontal cards) ──────────────
              SizedBox(
                height: 270,
                child: _filteredByCategory.isEmpty
                    ? Center(
                        child: Text('No ${_selectedCategory.toLowerCase()} spots yet',
                            style: const TextStyle(color: _P.inkSoft, fontSize: 14)),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: _filteredByCategory.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (_, i) => _buildBigCard(_filteredByCategory[i]),
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
                      content: const Text('Navigating to all favorites...', style: TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: _P.deepNavy,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      duration: const Duration(seconds: 1),
                    )
                  );
                }
              ),
              const SizedBox(height: 16),
              if (_favoritePlaces.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(20)),
                  child: const Column(
                    children: [
                      Icon(Icons.favorite_border_rounded, color: _P.inkSoft, size: 36),
                      SizedBox(height: 12),
                      Text('No favorites yet!', style: TextStyle(color: _P.deepNavy, fontSize: 15, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Tap the heart on any place to save it here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _P.inkSoft, fontSize: 13)),
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
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _buildFavChip(_favoritePlaces[i]),
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
                      content: const Text('Viewing top rated places...', style: TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: _P.blue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      duration: const Duration(seconds: 1),
                    )
                  );
                }
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 270,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: _popularPlaces.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
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
                      content: const Text('Viewing all packages...', style: TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: _P.navy,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      duration: const Duration(seconds: 1),
                    )
                  );
                }
              ),
              const SizedBox(height: 16),
              _packageCard('Island Hopping, 3 Days', 'Samal · Talikud · Eden', '₱4,500 / person', Icons.sailing_rounded, const [_P.skyBlue, _P.blue]),
              const SizedBox(height: 12),
              _packageCard('Forest Trek & Falls', 'Hagimit · Maxima · Ligid', '₱2,800 / person', Icons.forest_rounded, const [_P.skyBlue, _P.blue]),
              const SizedBox(height: 12),
              _packageCard('Sunset Mountain Tour', 'Mt. Puting Bato · Bali-Bali', '₱1,500 / person', Icons.wb_twilight_rounded, const [_P.blue, _P.navy]),

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
          gradient: LinearGradient(colors: place.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: place.gradient[1].withValues(alpha: 0.32), blurRadius: 20, offset: const Offset(0, 12))],
        ),
        child: Stack(
          children: [
            Positioned(top: -30, right: -30, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
            // Heart
            Positioned(
              top: 16, right: 16,
              child: GestureDetector(
                onTap: () => _toggleFavorite(place),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: place.isLiked ? Colors.white : Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    place.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: place.isLiked ? Colors.redAccent : Colors.grey,
                    size: 18,
                  ),
                ),
              ),
            ),
            // Rating
            Positioned(
              top: 16, left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(50)),
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 14),
                  const SizedBox(width: 3),
                  Text(place.rating.toString(), style: const TextStyle(color: _P.deepNavy, fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
            // Details
            Positioned(
              bottom: 18, left: 18, right: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Expanded(child: Text(place.location, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  ]),
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
          gradient: LinearGradient(colors: place.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: place.gradient[1].withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(place.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                GestureDetector(
                  onTap: () => _toggleFavorite(place),
                  child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                ),
              ],
            ),
            Row(children: [
              const Icon(Icons.location_on_rounded, color: Colors.white60, size: 12),
              const SizedBox(width: 4),
              Expanded(child: Text(place.location, style: const TextStyle(color: Colors.white60, fontSize: 11), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 12),
              const SizedBox(width: 2),
              Text(place.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ],
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════
  //  WEATHER CARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildWeatherCard() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = days[_now.weekday - 1];
    final dateStr = '${months[_now.month - 1]} ${_now.day}, ${_now.year}';
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final amPm = _now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute:$second $amPm';

    // Simulated weather based on time of day
    final isNight = _now.hour < 6 || _now.hour >= 18;
    final weatherIcon = isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded;
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
            top: -20, right: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: -10,
            child: Container(
              width: 70, height: 70,
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
                        const Icon(Icons.calendar_today_rounded, color: _P.skyBlue, size: 14),
                        const SizedBox(width: 6),
                        Text('$dayName, $dateStr', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: _P.skyBlue, size: 14),
                        const SizedBox(width: 4),
                        const Text('Samal Island, Davao', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              // Right side: weather
              Column(
                children: [
                  Icon(weatherIcon, color: isNight ? _P.skyBlue : const Color(0xFFFFA726), size: 40),
                  const SizedBox(height: 6),
                  Text('$temp\u00B0C', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(weatherLabel, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
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
        Text(title, style: const TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onTap,
            child: Text(action, style: const TextStyle(color: _P.blue, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _sectionHeaderWithIcon(String title, IconData icon, Color iconColor, String action, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
            const SizedBox(width: 6),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onTap,
            child: Text(action, style: const TextStyle(color: _P.blue, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _packageCard(String title, String subtitle, String price, IconData icon, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _P.deepNavy, fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: _P.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                Text(price, style: const TextStyle(color: _P.navy, fontSize: 13.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: _P.iceBlue, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: _P.deepNavy, size: 18),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Beach': return Icons.beach_access_rounded;
      case 'Forest': return Icons.park_rounded;
      case 'Mountain': return Icons.landscape_rounded;
      case 'Island': return Icons.water_rounded;
      default: return Icons.place_rounded;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
