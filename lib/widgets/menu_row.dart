import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'glass_panel.dart';

/// One row of a settings-style list: an icon, a label, and a chevron —
/// or, for [danger], a warning colour and no chevron.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.tertiary : AppColors.onSurface;

    return GlassPanel(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: AppTheme.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMd.copyWith(color: color),
                  ),
                ),
                if (!danger)
                  const Icon(
                    AppIcons.chevronRight,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
