import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'game_cover.dart';
import 'gradient_button.dart';

/// Featured game, laid out like the "Watch & learn in 60 seconds" block in
/// `games-design.webp`: headline and blurb, then a panel with the game's
/// numbers on the left and its artwork on the right, then a full-width red
/// button.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key, required this.game, this.onPlay});

  final Game game;
  final VoidCallback? onPlay;

  static const baseHeight = 380.0;

  /// The card is a fixed height (a [PageView] needs one), so it has to grow
  /// with the text scale. The artwork panel takes whatever is left over, so
  /// larger text squeezes the picture rather than overflowing the card.
  /// Clamped so a very large setting cannot produce an absurd slide.
  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return baseHeight * scale.clamp(1.0, 1.75);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTheme.sm,
            runSpacing: AppTheme.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _FeaturedBadge(),
              Text(
                game.category,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.goldInk,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            game.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headlineLgMobile.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (game.description.isNotEmpty) ...[
            const SizedBox(height: AppTheme.xs),
            Text(
              game.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 14,
                height: 20 / 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.md),
          Expanded(child: _ShowcasePanel(game: game)),
          const SizedBox(height: AppTheme.md),
          GradientButton(
            tone: ButtonTone.red,
            icon: AppIcons.playArrow,
            iconFill: 1,
            label: 'Play Now',
            expand: true,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

/// Numbers on a cream column beside the artwork, inside one white card.
class _ShowcasePanel extends StatelessWidget {
  const _ShowcasePanel({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: const Color(0xFFEDE3D0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(90, 66, 32, 0.08),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 96,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Stat(label: 'Played', value: _compact(game.playsCount)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.sm),
                  child: Divider(height: 1, color: AppColors.outlineVariant),
                ),
                _Stat(label: 'Rating', value: game.rating.toStringAsFixed(1)),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: GameCover(game: game),
            ),
          ),
        ],
      ),
    );
  }

  /// 2700 → "2.7k", as the reference writes its counts.
  static String _compact(int n) {
    if (n < 1000) return '$n';
    final k = n / 1000;
    return '${k >= 10 ? k.round() : k.toStringAsFixed(1)}k';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Scales down rather than overflowing the narrow column at large text.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 17),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
              fontSize: 11,
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
