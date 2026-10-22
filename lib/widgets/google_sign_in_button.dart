import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// "Continue with Google", styled to Google's white button.
///
/// The mark is a stand-in: shipping to a store means dropping Google's own
/// logo asset in here, which their branding terms require to be used as
/// supplied rather than redrawn.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, this.onPressed, this.busy = false});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLg);

    return Semantics(
      button: true,
      enabled: !busy && onPressed != null,
      label: context.tr('Lanjutkan dengan Google', 'Continue with Google'),
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onPressed,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4285F4),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _GoogleMark(),
                      const SizedBox(width: AppTheme.sm),
                      Flexible(
                        child: Text(
                          context.tr(
                            'Lanjutkan dengan Google',
                            'Continue with Google',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd.copyWith(
                            // Google's button uses its own near-black, not the
                            // app's palette, because the surface is white.
                            color: const Color(0xFF1F1F1F),
                            fontWeight: FontWeight.w600,
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

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF4285F4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          height: 1.15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A hairline with a word in it, separating the two ways to sign in.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label});

  /// Defaults to "or" in the current language.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        color: AppColors.outlineVariant.withValues(alpha: 0.5),
      ),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
          child: Text(
            label ?? context.tr('atau', 'or'),
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        line,
      ],
    );
  }
}
