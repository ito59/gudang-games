import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'top_bar.dart';

/// Header used by the non-home destinations: the same gold band as [TopBar],
/// with an optional back button and trailing action.
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

    return Container(
      height: height + topInset,
      padding: EdgeInsets.only(
        top: topInset,
        left: onBack == null ? AppTheme.marginMobile : AppTheme.sm,
        right: AppTheme.sm,
      ),
      decoration: const BoxDecoration(
        gradient: TopBar.gradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radiusSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(90, 66, 32, 0.12),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              tooltip: 'Back',
              icon: const Icon(AppIcons.arrowBack, color: AppColors.onSurface),
            ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headlineLgMobile.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 24 * -0.02,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
