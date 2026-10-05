import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// The primary action from `code.html`:
/// `bg-gradient-to-r from-primary-container to-inverse-primary` over a
/// violet bloom.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.iconFill = 0,
    this.expand = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double iconFill;

  /// Stretch to the available width (used on the profile page).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLg);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.inversePrimary],
        ),
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(124, 58, 237, 0.4), blurRadius: 20),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  fill: iconFill,
                  size: 24,
                  color: AppColors.onPrimaryContainer,
                ),
                const SizedBox(width: AppTheme.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.onPrimaryContainer,
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
