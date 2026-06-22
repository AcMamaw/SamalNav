import 'dart:ui';
import 'package:flutter/material.dart';

class MainLandingPage extends StatefulWidget {
  const MainLandingPage({super.key});

  @override
  State<MainLandingPage> createState() => _MainLandingPageState();
}

class _MainLandingPageState extends State<MainLandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF061020),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Section 1: Hero (100vh) ──────────────────────────────
            SizedBox(
              height: screenHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
          // ── Full-bleed background image ─────────────────────────────
          Image.network(
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D3B6E), Color(0xFF1A7C6E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D3B6E),
                    Color(0xFF1B6CA8),
                    Color(0xFF1A7C6E)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Dark gradient overlay ───────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0x331A1A2E),
                  Color(0xBB0D1B2A),
                  Color(0xF0061020),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // ── TOP BAR: fixed at the very top ──────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1),
                          ),
                          child: const Icon(Icons.navigation_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'SamalNav',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),

                    // User icon → Login
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/login'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BOTTOM CONTENT: hero text + buttons ─────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Hero text
                        const Text(
                          'Explore\nSamal\nIsland',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Subtitle
                        const Text(
                          'Life is all about the journey —\ndiscover your paradise here.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Get Started button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/home');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0D3B6E),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 10,
                              shadowColor: Colors.black45,
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sign In link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account?  ',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/login'),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ), // Positioned
          ],
        ),
      ),
      
      // ── Section 2: Connections / Features ─────────────────────
      _buildConnectionsSection(),

      // ── Section 3: About App ─────────────────────────────────
      _buildAboutSection(),

      // ── Section 4: Footer with Login/Register ──────────────────
      _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ── Helpers for new sections ──────────────────────────────────────────

  Widget _buildAboutSection() {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.network(
            'https://images.unsplash.com/photo-1559128010-7c1ad6e1b6a5?w=800&q=80',
            fit: BoxFit.cover,
          ),
        ),
        // Dark Overlay
        Positioned.fill(
          child: Container(
            color: const Color(0xFF0D1B2A).withOpacity(0.85),
          ),
        ),
        // Content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'About SamalNav',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'SamalNav is your ultimate companion for exploring the beautiful Island Garden City of Samal. Whether you are looking for the fastest ferry, the best resorts, or a local guide, we connect you to everything the island has to offer in one seamless experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 30),
              
              // Developer Contacts
              const Text(
                'Contact the Developers',
                style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialIcon(Icons.facebook),
                  const SizedBox(width: 24),
                  _socialIcon(Icons.camera_alt_outlined), // Placeholder for Instagram
                  const SizedBox(width: 24),
                  _socialIcon(Icons.email_rounded),
                ],
              ),
              const SizedBox(height: 40),

              // A decorative line or element
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildConnectionsSection() {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.network(
            'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&q=80',
            fit: BoxFit.cover,
          ),
        ),
        // Dark Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D1B2A).withOpacity(0.85),
                  const Color(0xFF061020).withOpacity(0.95),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Our Connections',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Everything you need for a perfect getaway.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const SizedBox(height: 40),
              
              // Grid of features
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 20,
                children: [
              _featureCard(
                Icons.directions_boat_rounded, 
                'Ferry Schedules', 
                'Real-time updates for barges and boats.'
              ),
              _featureCard(
                Icons.hotel_rounded, 
                'Resorts & Stays', 
                'Discover the best places to relax on the island.'
              ),
              _featureCard(
                Icons.map_rounded, 
                'Tour Guides', 
                'Connect with verified local island guides.'
              ),
              _featureCard(
                Icons.restaurant_rounded, 
                'Local Cuisine', 
                'Discover top-rated restaurants and eateries.'
              ),
            ],
          ),
        ],
      ),
    ),
      ],
    );
  }

  Widget _featureCard(IconData icon, String title, String subtitle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 165,
          height: 220, // Forces all cards to have the exact same height
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.35),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Icon(Icons.arrow_outward_rounded, color: Colors.white.withOpacity(0.5), size: 18),
                ],
              ),
              const SizedBox(height: 16),
              // Text
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.3),
              ),
              const Spacer(), // Pushes the pill to the very bottom
              // Bottom pill
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Explore', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.8), size: 8),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 20, left: 28, right: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF020611), // Even darker for footer
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const Text(
            'Join the Community',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create an account to save your favorite spots, book rides, and leave reviews.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 30),
          
          // Login and Register Buttons in Footer
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D3B6E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: Colors.white54, size: 16),
                  const SizedBox(width: 6),
                  const Text('SamalNav', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                ],
              ),
              const Text('© 2026 All Rights Reserved.', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
    ),
      ),
    );
  }
}
