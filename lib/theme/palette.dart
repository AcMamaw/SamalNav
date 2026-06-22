import 'package:flutter/material.dart';

// ── Palette: dark blue → blue → white ─────────────────────────────────
// A single hue family carried from deepest navy down to white. Shared
// across every screen so new pages stay on-system by default.
class AppPalette {
  static const white = Color(0xFFFFFFFF);
  static const iceBlue = Color(0xFFE3ECFB); // softest tint, for fills/chips
  static const skyBlue = Color(0xFF6FA8F5); // light blue, gradient highlight
  static const blue = Color(0xFF3B6FE0); // core signature accent
  static const navy = Color(0xFF13315C); // secondary dark
  static const deepNavy = Color(0xFF0A1F44); // darkest, for headline text
  static const inkSoft = Color(0xFF5B6B85); // muted slate for secondary text
}
