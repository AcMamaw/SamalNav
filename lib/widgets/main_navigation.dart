import 'package:flutter/material.dart';
import '../theme/palette.dart';
import '../screens/home/home_page.dart';
import '../screens/world/world_page.dart';
import '../screens/route/route_page.dart';
import '../screens/favorite/favorite_page.dart';
import '../screens/profile/profile_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const List<_NavTab> _tabs = [
    _NavTab(inactiveIcon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavTab(inactiveIcon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Map'),
    _NavTab(inactiveIcon: Icons.route_outlined, activeIcon: Icons.route_rounded, label: 'Route'),
    _NavTab(inactiveIcon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded, label: 'Favorite'),
    _NavTab(inactiveIcon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  late final List<Widget> _pages = [
    const HomePage(),
    const WorldPage(),
    const RoutePage(),
    const FavoritePage(),
    const ProfilePage(),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    final routes = ['/home', '/world', '/message', '/favorite', '/profile'];
    Navigator.of(context).pushReplacementNamed(
      routes[index],
      arguments: {'isTabSwitch': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppPalette.deepNavy.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_tabs.length, (i) {
                    final tab = _tabs[i];
                    final isSelected = _currentIndex == i;
                    return _NavItemWidget(
                      tab: tab,
                      isSelected: isSelected,
                      onTap: () => _onTabTapped(i),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatefulWidget {
  final _NavTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final tab = widget.tab;

    // "if i hover in the icon it color blue but dont show the name if i press then there the time you show the name ok??"
    final iconColor = isSelected
        ? Colors.white
        : (_isHovered ? AppPalette.blue : AppPalette.inkSoft);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 18 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppPalette.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 280),
                style: TextStyle(color: iconColor),
                child: Icon(
                  isSelected ? tab.activeIcon : tab.inactiveIcon,
                  color: iconColor,
                  size: 23,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  tab.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────
class _NavTab {
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String label;
  const _NavTab({required this.inactiveIcon, required this.activeIcon, required this.label});
}

// ── Placeholder page ───────────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderPage({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: const BoxDecoration(
                  color: AppPalette.iceBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: AppPalette.blue),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.deepNavy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.inkSoft,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
