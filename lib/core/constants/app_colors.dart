import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0A0A0F);
  static const Color cardBackground = Color(0xFF1A1A2E);
  static const Color surfaceColor = Color(0xFF16213E);
  static const Color bottomNavBackground = Color(0xFF0F0F1A);

  // Primary Colors
  static const Color primaryPurple = Color(0xFF7B2FFF);
  static const Color deepPurple = Color(0xFF5B1FCC);
  static const Color lightPurple = Color(0xFF9B5FFF);

  // Accent Colors
  static const Color neonPink = Color(0xFFFF2D78);
  static const Color hotPink = Color(0xFFFF006E);
  static const Color coralPink = Color(0xFFFF6B8A);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF7B2FFF),
    Color(0xFFFF2D78),
  ];

  static const List<Color> purpleGradient = [
    Color(0xFF5B1FCC),
    Color(0xFF9B5FFF),
  ];

  static const List<Color> pinkGradient = [
    Color(0xFFFF2D78),
    Color(0xFFFF6B8A),
  ];

  static const List<Color> premiumGradient = [
    Color(0xFFFFD700),
    Color(0xFFFF8C00),
    Color(0xFFFF2D78),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0A0A0F),
    Color(0xFF1A1A2E),
  ];

  static const List<Color> matchGradient = [
    Color(0xFF7B2FFF),
    Color(0xFFFF2D78),
    Color(0xFFFFD700),
  ];

  // Status Colors
  static const Color onlineGreen = Color(0xFF00E676);
  static const Color offlineGray = Color(0xFF616161);
  static const Color errorRed = Color(0xFFFF3D3D);
  static const Color warningYellow = Color(0xFFFFD600);
  static const Color successGreen = Color(0xFF00E676);

  // Neutral
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white54 = Colors.white54;
  static const Color white38 = Colors.white38;
  static const Color white12 = Colors.white12;

  // Special
  static const Color coinGold = Color(0xFFFFD700);
  static const Color diamondBlue = Color(0xFF00B4D8);
  static const Color superLikeBlue = Color(0xFF00B4FF);
  static const Color verifiedBlue = Color(0xFF1DA1F2);
}
