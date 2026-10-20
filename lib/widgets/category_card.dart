import 'package:flutter/material.dart';

import '../models/game_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// One shortcut in the home menu grid: a line icon in its accent colour
/// over a short label, like the Profile / Top player / Tutorial grid in
/// `games-design.webp`. The chosen category gets a tinted rounded square.
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
  /// launch and wherever it appears.
  static Color accentFor(String key) =>
      accents[key.codeUnits.fold(0, (a, b) => a + b) % accents.length];

  @override
  Widget build(BuildContext context) {
    final accent = accentFor(
      category.slug.isEmpty ? category.label : category.slug,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  category.icon,
                  size: 32,
                  fill: selected ? 1 : 0,
                  weight: 300,
                  color: accent,
                ),
              ),
              const SizedBox(height: AppTheme.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
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
    );
  }
}
