import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Header used by the non-home destinations: same blurred surface and violet
/// bloom as [TopBar], with an optional back button and trailing action.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  static const height = 64.0;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: height + topInset,
          padding: EdgeInsets.only(
            top: topInset,
            left: onBack == null ? AppTheme.marginMobile : AppTheme.sm,
            right: AppTheme.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(115, 46, 228, 0.15),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Back',
                  icon: const Icon(
                    AppIcons.arrowBack,
                    color: AppColors.onSurface,
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 24 * -0.05,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
