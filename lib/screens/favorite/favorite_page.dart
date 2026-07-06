import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/palette.dart';

// Same AppPalette shorthand used across the app
typedef _P = AppPalette;

final _supabase = Supabase.instance.client;

// ── Data Model ──────────────────────────────────────────────────────
class FavoriteItem {
  final String id; // Supabase row ID for deletion
  final String name;
  final String location;
  final double rating;
  final String category;
  final List<Color> gradient;
  bool isLiked;

  FavoriteItem({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.category,
    required this.gradient,
    this.isLiked = true,
  });

  // Map category → gradient colors
  static List<Color> gradientForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'beach':
        return [_P.skyBlue, _P.deepNavy];
      case 'island':
        return [_P.skyBlue, _P.navy];
      case 'resort':
        return [_P.skyBlue, _P.blue];
      case 'falls':
        return [_P.blue, _P.navy];
      case 'mountain':
        return [_P.navy, _P.deepNavy];
      case 'historical':
        return [_P.blue, _P.deepNavy];
      case 'park':
        return [_P.skyBlue, _P.blue];
      default:
        return [_P.blue, _P.deepNavy];
    }
  }
}

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  String _selectedFilter = 'All';
  bool _isLoading = true;
  bool _hasError = false;

  // Loaded from Supabase
  List<FavoriteItem> _favorites = [];

  // "Recently Viewed" remains local — no backend table for this yet
  final List<FavoriteItem> _recentlyViewed = [
    FavoriteItem(id: 'rv1', name: 'Secdea Beach Resort', location: 'Babak, Samal Island', rating: 4.8, category: 'Resort', gradient: [_P.navy, _P.blue], isLiked: false),
    FavoriteItem(id: 'rv2', name: 'Maxima Aquafun', location: 'Penaplata, Samal Island', rating: 4.6, category: 'Park', gradient: [_P.skyBlue, _P.blue], isLiked: false),
    FavoriteItem(id: 'rv3', name: 'Monfort Bat Cave', location: 'Babak, Samal Island', rating: 4.5, category: 'Historical', gradient: [_P.blue, _P.deepNavy], isLiked: false),
    FavoriteItem(id: 'rv4', name: 'Canibad Beach', location: 'Babak District', rating: 4.6, category: 'Beach', gradient: [_P.skyBlue, _P.navy], isLiked: false),
  ];

  static const _filterOptions = ['All', 'Beach', 'Island', 'Resort', 'Falls', 'Mountain'];

  List<FavoriteItem> get _filteredFavorites {
    if (_selectedFilter == 'All') return _favorites;
    return _favorites.where((f) => f.category == _selectedFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // ── Supabase: Load favorites for current user ──────────────────────
  Future<void> _loadFavorites() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<FavoriteItem> loaded = (data as List).map((row) {
        final category = (row['category'] as String?) ?? 'Other';
        return FavoriteItem(
          id: row['id'].toString(),
          name: row['place_name'] as String? ?? '',
          location: row['location'] as String? ?? '',
          rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
          category: category,
          gradient: FavoriteItem.gradientForCategory(category),
        );
      }).toList();

      if (mounted) setState(() => _favorites = loaded);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Supabase: Remove favorite ──────────────────────────────────────
  Future<void> _removeFavorite(FavoriteItem item) async {
    // Optimistic UI: remove immediately
    setState(() => _favorites.remove(item));

    try {
      await _supabase.from('favorites').delete().eq('id', item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed from favorites.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: _P.deepNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            action: SnackBarAction(
              label: 'Undo',
              textColor: _P.skyBlue,
              onPressed: () async {
                // Re-insert
                final user = _supabase.auth.currentUser;
                if (user == null) return;
                await _supabase.from('favorites').insert({
                  'user_id': user.id,
                  'place_name': item.name,
                  'location': item.location,
                  'rating': item.rating,
                  'category': item.category,
                });
                _loadFavorites();
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() => _favorites.insert(0, item));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to remove favorite. Try again.',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _P.blue, strokeWidth: 2.5),
                    SizedBox(height: 16),
                    Text('Loading your favorites...', style: TextStyle(color: _P.inkSoft, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: _P.inkSoft, size: 48),
                        const SizedBox(height: 16),
                        const Text('Could not load favorites.', style: TextStyle(color: _P.deepNavy, fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _loadFavorites,
                          icon: const Icon(Icons.refresh_rounded, color: _P.blue),
                          label: const Text('Retry', style: TextStyle(color: _P.blue, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: _P.blue,
                    onRefresh: _loadFavorites,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Header ──────────────────────────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'My Favorites',
                                          style: TextStyle(
                                            color: _P.deepNavy,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.8,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Places you loved and saved for later.',
                                          style: TextStyle(
                                            color: _P.inkSoft,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _P.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_favorites.length} saved',
                                      style: const TextStyle(
                                        color: _P.blue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Plan from Favorites Banner ──────────────────────
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_P.blue, _P.deepNavy],
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
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.route_rounded, color: Colors.white, size: 20),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Switching to Plan tab to create your route!',
                                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: _P.deepNavy,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            right: -20,
                                            top: -20,
                                            child: CircleAvatar(
                                              radius: 45,
                                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.18),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 26),
                                              ),
                                              const SizedBox(width: 16),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Plan Route from Favorites',
                                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'Turn your saved spots into an optimized tour!',
                                                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w400),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── Category Filters ────────────────────────────────
                              _sectionHeaderWithIcon('Saved Favorites', Icons.favorite_rounded, Colors.redAccent, '${_filteredFavorites.length} shown'),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                child: Row(
                                  children: _filterOptions.map((f) {
                                    final selected = _selectedFilter == f;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedFilter = f),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeInOut,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: selected ? _P.deepNavy : Colors.white,
                                            borderRadius: BorderRadius.circular(30),
                                            border: Border.all(
                                              color: selected ? _P.deepNavy : Colors.grey.withValues(alpha: 0.15),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: selected
                                                    ? _P.deepNavy.withValues(alpha: 0.15)
                                                    : Colors.black.withValues(alpha: 0.02),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            f,
                                            style: TextStyle(
                                              color: selected ? Colors.white : _P.navy,
                                              fontSize: 14,
                                              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Filtered Favorites List ─────────────────────────
                              _filteredFavorites.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(Icons.favorite_border_rounded, color: _P.inkSoft, size: 48),
                                          const SizedBox(height: 14),
                                          const Text('No favorites yet', style: TextStyle(color: _P.deepNavy, fontSize: 16, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedFilter == 'All'
                                                ? 'Start exploring and tap ♡ to save places here.'
                                                : 'No $_selectedFilter favorites found. Try "All".',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: _P.inkSoft, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _filteredFavorites.length,
                                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                                      itemBuilder: (_, i) => _buildVerticalCard(_filteredFavorites[i]),
                                    ),

                              const SizedBox(height: 36),

                              // ── Recently Viewed Section ─────────────────────────
                              _sectionHeaderWithIcon('Recently Viewed', Icons.history_rounded, _P.blue, ''),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 175,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  clipBehavior: Clip.none,
                                  itemCount: _recentlyViewed.length,
                                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                                  itemBuilder: (_, i) => _buildHorizontalCard(_recentlyViewed[i]),
                                ),
                              ),

                              const SizedBox(height: 36),

                              // ── Stats Summary ───────────────────────────────────
                              _buildStatsSummary(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  // ── Stats Summary ───────────────────────────────────────────────────
  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Travel Stats', style: TextStyle(color: _P.deepNavy, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Row(
            children: [
              _statItem(Icons.favorite_rounded, '${_favorites.length}', 'Saved', Colors.redAccent),
              _verticalDivider(),
              _statItem(Icons.visibility_rounded, '${_recentlyViewed.length}', 'Viewed', _P.blue),
              _verticalDivider(),
              _statItem(Icons.star_rounded, '4.8', 'Avg Rating', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: _P.deepNavy, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _P.inkSoft, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 45, color: Colors.grey.withValues(alpha: 0.2));
  }

  Widget _sectionHeaderWithIcon(String title, IconData icon, Color iconColor, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(color: _P.deepNavy, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(width: 6),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
        if (action.isNotEmpty)
          Text(action, style: const TextStyle(color: _P.blue, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // BIG VERTICAL CARD FOR FAVORITES
  Widget _buildVerticalCard(FavoriteItem item) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: item.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: item.gradient[1].withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Opening ${item.name}...',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: _P.deepNavy,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -40,
                  child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withValues(alpha: 0.06)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            item.category.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                        // Unlike/Remove button
                        GestureDetector(
                          onTap: () => _removeFavorite(item),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                                  const SizedBox(width: 3),
                                  Text(item.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: Colors.white.withValues(alpha: 0.75), size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, fontWeight: FontWeight.w400),
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
        ),
      ),
    );
  }

  // SMALL HORIZONTAL CARD FOR RECENTLY VIEWED
  Widget _buildHorizontalCard(FavoriteItem item) {
    return Container(
      width: 155,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: item.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: item.gradient[1].withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Opening ${item.name}...',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: _P.deepNavy,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Positioned(
                  top: -25,
                  right: -25,
                  child: CircleAvatar(radius: 35, backgroundColor: Colors.white.withValues(alpha: 0.06)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(30)),
                      child: Text(
                        item.category,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.2),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                            const SizedBox(width: 3),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
        ),
      ),
    );
  }
}
