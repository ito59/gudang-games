import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'game_cover.dart';
import 'glass_panel.dart';
import 'gradient_button.dart';

/// Hero slide for a featured game: 400px tall, artwork behind a bottom-up
/// scrim, content pinned to the bottom edge.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key, required this.game, this.onPlay});

  final Game game;
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
            GameCover(game: game),
            // A warm dark scrim, so the white headline reads over any art.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0, 0.55, 1],
                  colors: [
                    Color.fromRGBO(38, 26, 10, 0.92),
                    Color.fromRGBO(38, 26, 10, 0.45),
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
                        const _FeaturedBadge(),
                        _CategoryBadge(label: game.category),
                      ],
                    ),
                    const SizedBox(height: AppTheme.md),
                    Text(
                      game.title,
                      // Bounded so a large text setting cannot grow the
                      // headline past the height reserved for the card.
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displayLg.copyWith(
                        color: AppColors.onImage,
                        shadows: const [
                          Shadow(
                            color: Color.fromRGBO(0, 0, 0, 0.5),
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    if (game.description.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.md),
                      Text(
                        game.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onImage.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.md),
                    GradientButton(
                      tone: ButtonTone.red,
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

/// Solid red pill with a star.
class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            AppIcons.star,
            fill: 1,
            size: 12,
            color: AppColors.onImage,
          ),
          const SizedBox(width: AppTheme.xs),
          Text(
            'FEATURED',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onImage,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold pill with dark ink.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldLight],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onGold,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
