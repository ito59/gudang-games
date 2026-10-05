import 'package:flutter/material.dart';

import '../models/game_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'glass_panel.dart';

/// Category chip: 90x90 glass panel, icon in a `bg-surface-variant` circle.
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

  @override
  Widget build(BuildContext context) {
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
                    color: selected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    size: 24,
                    color: selected
                        ? AppColors.onPrimaryContainer
                        : AppColors.primary,
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
                      color: selected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
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
