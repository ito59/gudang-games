import 'package:flutter/material.dart';

import '../models/game_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A category filter chip: its icon in the category's accent colour beside
/// the name, in a white pill. The chosen one is tinted and outlined in that
/// accent.
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
    final radius = BorderRadius.circular(999);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected
            ? accent.withValues(alpha: 0.14)
            : AppColors.surfaceContainer,
        borderRadius: radius,
        border: Border.all(
          color: selected ? accent : AppColors.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 16, 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 20,
                  fill: selected ? 1 : 0,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Text(
                  category.label,
                  maxLines: 1,
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 14,
                    color: AppColors.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
