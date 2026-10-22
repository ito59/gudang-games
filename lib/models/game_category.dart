import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../theme/app_icons.dart';

class GameCategory {
  const GameCategory({
    required this.label,
    required this.icon,
    this.slug = '',
  });

  /// Builds a category from the `/api/v1/categories` payload.
  factory GameCategory.fromJson(Map<String, dynamic> json) {
    return GameCategory(
      label: (json['label'] as String?) ?? tr('Game', 'Games'),
      slug: (json['slug'] as String?) ?? '',
      icon: iconFor(json['icon'] as String?),
    );
  }

  final String label;

  /// Matches `category_slug` on a game.
  final String slug;
  final IconData icon;

  /// The backend stores a Material Symbols glyph name; the app ships only the
  /// glyphs it uses, so anything unmapped falls back to a generic pad.
  static IconData iconFor(String? name) => switch (name) {
    'swords' => AppIcons.swords,
    'magic_button' => AppIcons.magicButton,
    'chess' => AppIcons.chess,
    'sports_soccer' => AppIcons.sportsSoccer,
    'speed' => AppIcons.speed,
    'bolt' => AppIcons.bolt,
    'trophy' => AppIcons.trophy,
    'sports_esports' || _ => AppIcons.videogameAsset,
  };
}
