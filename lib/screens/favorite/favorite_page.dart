import 'package:flutter/material.dart';
import '../../theme/palette.dart';

// Same AppPalette shorthand
typedef _P = AppPalette;

class FavoriteItem {
  final String name;
  final String location;
  final double rating;
  final List<Color> gradient;
  final bool isLiked;

  const FavoriteItem(this.name, this.location, this.rating, this.gradient, this.isLiked);
}

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  // Mock Favorites
  final List<FavoriteItem> _favorites = const [
    FavoriteItem('Pearl Farm Resort', 'Kaputian, Samal Island', 4.9, [_P.skyBlue, _P.blue], true),
    FavoriteItem('Hagimit Falls', 'Penaplata, Samal Island', 4.7, [_P.blue, _P.navy], true),
    FavoriteItem('Talikud Island', 'Kaputian District', 4.8, [_P.skyBlue, _P.navy], true),
  ];

  // Mock Recently Viewed
  final List<FavoriteItem> _recentlyViewed = const [
    FavoriteItem('Secdea Beach Resort', 'Babak, Samal Island', 4.8, [_P.navy, _P.blue], false),
    FavoriteItem('Maxima Aquafun', 'Penaplata, Samal Island', 4.6, [_P.skyBlue, _P.blue], false),
    FavoriteItem('Monfort Bat Cave', 'Babak, Samal Island', 4.5, [_P.blue, _P.deepNavy], false),
    FavoriteItem('Vanishing Island', 'Babak District', 4.7, [_P.skyBlue, _P.navy], false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit from MainNavigation
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text('My Favorites', style: TextStyle(color: _P.deepNavy, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  const Text('Places you loved and saved for later.', style: TextStyle(color: _P.inkSoft, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 30),

                  // Favorites Section
                  _sectionHeaderWithIcon('Saved Favorites', Icons.favorite_rounded, Colors.redAccent, '${_favorites.length} saved'),
                  const SizedBox(height: 16),
                  
                  // Vertical list of favorites
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _favorites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => _buildVerticalCard(_favorites[i]),
                  ),
                  
                  const SizedBox(height: 40),

                  // Recently Viewed Section
                  _sectionHeaderWithIcon('Recently Viewed', Icons.history_rounded, _P.blue, ''),
                  const SizedBox(height: 16),

                  // Horizontal list of recently viewed
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: _recentlyViewed.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (_, i) => _buildHorizontalCard(_recentlyViewed[i]),
                    ),
                  ),
                  
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeaderWithIcon(String title, IconData icon, Color iconColor, String action) {
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
          Text(action, style: const TextStyle(color: _P.blue, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // BIG VERTICAL CARD FOR FAVORITES
  Widget _buildVerticalCard(FavoriteItem item) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: item.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: item.gradient[1].withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          // Background graphic
          Positioned(top: -30, right: -30, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
          
          // Heart Icon
          Positioned(
            top: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
            ),
          ),
          
          // Details
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2), overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(50)),
                      child: Row(children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 12),
                        const SizedBox(width: 3),
                        Text(item.rating.toString(), style: const TextStyle(color: _P.deepNavy, fontSize: 12, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 13),
                  const SizedBox(width: 4),
                  Expanded(child: Text(item.location, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SMALL HORIZONTAL CARD FOR RECENTLY VIEWED
  Widget _buildHorizontalCard(FavoriteItem item) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Gradient icon & Heart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: item.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.image_rounded, color: Colors.white, size: 20),
              ),
              const Icon(Icons.favorite_border_rounded, color: Colors.grey, size: 20),
            ],
          ),
          const Spacer(),
          Text(item.name, style: const TextStyle(color: _P.deepNavy, fontSize: 13.5, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_rounded, color: _P.inkSoft, size: 12),
            const SizedBox(width: 2),
            Expanded(child: Text(item.location, style: const TextStyle(color: _P.inkSoft, fontSize: 11), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 12),
            const SizedBox(width: 2),
            Text(item.rating.toString(), style: const TextStyle(color: _P.navy, fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ],
      ),
    );
  }
}
