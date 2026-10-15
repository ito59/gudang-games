import 'package:flutter/material.dart';

/// Warm cream-and-gold palette from `games-design.webp`: cream page, white
/// cards, a gold header band, deep red for the primary action and the active
/// state, near-black ink for text.
///
/// Token names are the Material 3 roles the screens were written against, so
/// every call site picks up the new palette without changes.
class AppColors {
  const AppColors._();

  // Surfaces
  static const background = Color(0xFFF7F1E5);
  static const surface = Color(0xFFF7F1E5);
  static const surfaceDim = Color(0xFFEFE6D4);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFFCF8F0);
  static const surfaceContainer = Color(0xFFFFFFFF);
  static const surfaceContainerHigh = Color(0xFFF4ECDC);
  static const surfaceContainerHighest = Color(0xFFEDE2CB);
  static const surfaceVariant = Color(0xFFF5EBD6);
  static const surfaceBright = Color(0xFFFFFFFF);

  // Primary — the deep red of "Start game" and the active tab.
  static const primary = Color(0xFFB3191E);
  static const primaryContainer = Color(0xFFC21F24);
  static const onPrimaryContainer = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFFFF8EC);
  static const inversePrimary = Color(0xFF8F1217);

  // Secondary / tertiary
  static const secondaryContainer = Color(0xFFD2B272);
  static const tertiary = Color(0xFFC0700F);
  static const tertiaryContainer = Color(0xFFE0861C);

  // Content
  static const onSurface = Color(0xFF221C15);
  static const onSurfaceVariant = Color(0xFF6E6254);
  static const onBackground = Color(0xFF221C15);
  static const outlineVariant = Color(0xFFDCCDB0);

  // Gold — the header band and the secondary "Start Game" / "Add Funds"
  // buttons, light at the top-right and deepening toward the bottom-left.
  static const goldLight = Color(0xFFF3E4BF);
  static const gold = Color(0xFFD9BC80);
  static const goldDeep = Color(0xFFBF9A55);
  static const onGold = Color(0xFF2B2116);

  /// "Welcome Bonus" heading gold — readable on white, unlike [gold].
  static const goldInk = Color(0xFFA9823D);

  /// Text and icons laid over artwork, behind a dark scrim.
  static const onImage = Color(0xFFFFFBF3);

  /// Warm brown used for scrims over artwork and for soft drop shadows, so
  /// neither reads as a cold grey on the cream page.
  static const shadow = Color(0xFF5A4220);

  /// Presence dot. Darker than a neon green so it holds up on white.
  static const online = Color(0xFF2BA55A);
}
