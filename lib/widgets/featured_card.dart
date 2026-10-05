import 'package:flutter/material.dart';

import '../models/featured_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'glass_panel.dart';
import 'gradient_button.dart';

/// Hero `<section>`: 400px tall, artwork behind a bottom-up scrim,
/// content pinned to the bottom edge.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key, required this.event, this.onPlay});

  final FeaturedEvent event;
  final VoidCallback? onPlay;

  /// Hero height from `code.html` (`h-[400px]`).
  static const baseHeight = 400.0;

  /// The card is a fixed height (a [PageView] needs one), so it has to grow
  /// with the text scale or the headline pushes the badges out of the top of
  /// the card — silently, since the content is bottom-anchored in a [Stack].
  /// Clamped so a very large setting cannot produce an absurd hero.
  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return baseHeight * scale.clamp(1.0, 1.75);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightFor(context),
      child: GlassPanel(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (event.image.isEmpty)
              const ColoredBox(color: AppColors.surfaceContainerHigh)
            else if (event.imageIsRemote)
              Image.network(
                event.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: AppColors.surfaceContainerHigh),
              )
            else
              Image.asset(
                event.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: AppColors.surfaceContainerHigh),
              ),
            // from-background via-background/60 to-transparent
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.background,
                    Color.fromRGBO(11, 19, 38, 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Wrap, not Row: at larger text scales the two badges no
                    // longer fit side by side and must reflow.
                    Wrap(
                      spacing: AppTheme.sm,
                      runSpacing: AppTheme.sm,
                      children: [
                        if (event.isLive) const _LiveBadge(),
                        _SeasonBadge(label: event.season),
                      ],
                    ),
                    const SizedBox(height: AppTheme.md),
                    Text(
                      event.title,
                      // Bounded so a large text setting cannot grow the
                      // headline past the height reserved for the card.
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displayLg.copyWith(
                        color: AppColors.primaryFixed,
                        shadows: const [
                          Shadow(
                            color: Color.fromRGBO(0, 0, 0, 0.5),
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.md),
                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTheme.md),
                    GradientButton(
                      icon: AppIcons.playArrow,
                      iconFill: 1,
                      label: 'Play Now',
                      onPressed: onPlay,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `bg-tertiary-container/20`, `border-tertiary/20`, pulsing dot.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 8, height: 8),
          ),
          const SizedBox(width: AppTheme.xs),
          Text(
            'LIVE EVENT',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.tertiary),
          ),
        ],
      ),
    );
  }
}

/// `bg-surface-variant/60`, `border-outline-variant/30`.
class _SeasonBadge extends StatelessWidget {
  const _SeasonBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface),
      ),
    );
  }
}
