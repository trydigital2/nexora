import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Secondary
  static const Color primary = Color(0xFF10172A); // Deep navy
  static const Color primaryLight = Color(0xFF1E293B);
  static const Color primaryDark = Color(0xFF0A0F1D);
  static const Color secondary = Color(0xFF7257E8); // Purple
  static const Color secondaryLight = Color(0xFF9078F3);
  static const Color accent = Color(0xFF35C99A); // Mint green
  static const Color accentLight = Color(0xFF5FE1B6);

  // Backgrounds & Surfaces (Light)
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F4F9);

  // Backgrounds & Surfaces (Dark)
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF131B2E);
  static const Color darkSurfaceAlt = Color(0xFF1E273E);
  static const Color darkCard = Color(0xFF182238);

  // Functional / Status
  static const Color success = Color(0xFF35C99A);
  static const Color expense = Color(0xFFFF5C5C); // Red for expenses
  static const Color income = Color(0xFF35C99A); // Mint for income
  static const Color warning = Color(0xFFFFB800);
  static const Color info = Color(0xFF38BDF8);

  // Text
  static const Color textPrimary = Color(0xFF10172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDarkMuted = Color(0xFF94A3B8);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF243048);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7257E8), Color(0xFF5434D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF10172A), Color(0xFF1A2744), Color(0xFF2C2250)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF35C99A), Color(0xFF1FAF82)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGlowGradient = LinearGradient(
    colors: [Color(0xFF7257E8), Color(0xFF35C99A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

