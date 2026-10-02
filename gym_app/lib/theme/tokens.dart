import 'package:flutter/material.dart';

/// Design tokens — clean / professionale / minimale (PRD §2.1).
abstract final class AppTokens {
  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceHigh = Color(0xFF1E1E1E);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color accent = Color(0xFFE8E8E8);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFE5484D);
  static const Color success = Color(0xFF3DDC97);

  static const double radius = 8;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );
}
