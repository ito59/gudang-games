import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'game_cover.dart';
import 'glass_panel.dart';

/// Game tile: 160px cover, category pill top-right, title and rating below.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    this.onTap,
    this.onPlayTrailer,
  });

  final Game game;
  final VoidCallback? onTap;

  /// Separate from [onTap] so watching a trailer never starts the game.
  final VoidCallback? onPlayTrailer;

  static const coverHeight = 160.0;
  static const _padding = 12.0;
  static const _starSize = 14.0;

  /// Height this card needs at the current text scale.
  ///
  /// The grid must not hard-code a number: the title and rating lines grow
  /// with the user's font-size setting, and a fixed extent overflows as soon
  /// as that setting is above 100%.
  static double extentFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);

    double lineHeight(TextStyle style) =>
        scaler.scale(style.fontSize!) * (style.height ?? 1);

    final title = lineHeight(AppTextStyles.cardTitle);
    final rating = math.max(_starSize, lineHeight(AppTextStyles.labelSm));

    return coverHeight + _padding * 2 + title + AppTheme.xs + rating;
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flexible so any leftover or missing pixel lands on the cover
              // instead of overflowing the text below it.
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameCover(game: game),
                      Positioned(
                        top: AppTheme.sm,
                        right: AppTheme.sm,
                        child: _CategoryPill(label: game.category),
                      ),
                      if (game.hasTrailer)
                        Positioned(
                          left: AppTheme.sm,
                          bottom: AppTheme.sm,
                          child: _TrailerButton(onTap: onPlayTrailer),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(_padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: AppTheme.xs),
                    Row(
                      children: [
                        const Icon(
                          AppIcons.star,
                          fill: 1,
                          size: _starSize,
                          color: AppColors.tertiary,
                        ),
                        const SizedBox(width: AppTheme.xs),
                        Text(
                          game.rating.toStringAsFixed(1),
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlaid on the cover so a trailer is one tap away, without stealing the
/// card's own tap.
class _TrailerButton extends StatelessWidget {
  const _TrailerButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.playCircle,
                fill: 1,
                size: 14,
                color: AppColors.onSurface,
              ),
              const SizedBox(width: AppTheme.xs),
              Text(
                'Trailer',
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 10,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 10,
          color: AppColors.onPrimaryContainer,
        ),
      ),
    );
  }
}
