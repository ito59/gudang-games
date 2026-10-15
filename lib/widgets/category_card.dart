import 'package:flutter/material.dart';

import '../models/game_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'glass_panel.dart';

/// Category chip: 90x90 white card, its icon tinted in one of the cheerful
/// accents of the reference's shortcut grid.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.selected = false,
  });

  final GameCategory category;
  final VoidCallback? onTap;

  /// Whether this category is the one currently being browsed.
  final bool selected;

  /// Green, red, orange, gold, crimson — the shortcut icons in
  /// `games-design.webp`.
  static const accents = [
    Color(0xFF2E9E5B),
    Color(0xFFC62828),
    Color(0xFFE07A1F),
    Color(0xFFB8913F),
    Color(0xFFA3195B),
  ];

  /// A stable accent per category, so "Action" is the same colour on every
  /// launch and wherever it appears in the strip.
  static Color accentFor(String key) =>
      accents[key.codeUnits.fold(0, (a, b) => a + b) % accents.length];

  @override
  Widget build(BuildContext context) {
    final accent = accentFor(
      category.slug.isEmpty ? category.label : category.slug,
    );

    return SizedBox(
      width: 90,
      height: 90,
      child: GlassPanel(
        neonGlow: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? accent : accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    size: 24,
                    color: selected ? AppColors.onPrimaryContainer : accent,
                  ),
                ),
                const SizedBox(height: AppTheme.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 13,
                      color: AppColors.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
