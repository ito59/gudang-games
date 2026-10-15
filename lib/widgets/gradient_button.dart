import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Which of the two pill buttons from `games-design.webp` to draw.
enum ButtonTone {
  /// Gold gradient with dark ink — "Add Funds", "Start Game" in a sheet.
  gold,

  /// Solid deep red with white ink — the one "Start game" on a page.
  red,
}

/// The primary action: a full-round pill, gold by default.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.iconFill = 0,
    this.expand = false,
    this.tone = ButtonTone.gold,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double iconFill;

  /// Stretch to the available width (used on the profile page).
  final bool expand;

  final ButtonTone tone;

  static const _gold = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.goldDeep, AppColors.gold, AppColors.goldLight],
  );

  static const _red = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryContainer, AppColors.inversePrimary],
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    final red = tone == ButtonTone.red;
    final ink = red ? AppColors.onPrimaryContainer : AppColors.onGold;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: red ? _red : _gold,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: red
                ? const Color.fromRGBO(179, 25, 30, 0.30)
                : const Color.fromRGBO(191, 154, 85, 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, fill: iconFill, size: 22, color: ink),
                const SizedBox(width: AppTheme.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: ink,
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
