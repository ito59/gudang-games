import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'game_cover.dart';

/// One row in the home game list: square cover on the left, title with
/// category and rating beside it, and a gold play disc at the end.
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

  /// 3:2, the shape of most game covers, so the art is not cropped to a
  /// square sliver.
  static const coverSize = Size(120, 80);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: const Color(0xFFEDE3D0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: SizedBox.fromSize(
                  size: coverSize,
                  child: GameCover(game: game),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 6),
                    // Wrap so the pill, rating and trailer reflow under a
                    // large text setting instead of overflowing the row.
                    Wrap(
                      spacing: AppTheme.sm,
                      runSpacing: AppTheme.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CategoryPill(label: game.category),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppIcons.star,
                              fill: 1,
                              size: 14,
                              color: AppColors.goldDeep,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              game.rating.toStringAsFixed(1),
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (game.hasTrailer)
                          _TrailerButton(onTap: onPlayTrailer),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              const _PlayDisc(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The gold round button from the reference's balance sheet. Decorative:
/// the whole row is the tap target.
class _PlayDisc extends StatelessWidget {
  const _PlayDisc();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(191, 154, 85, 0.35),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        AppIcons.playArrow,
        fill: 1,
        size: 22,
        color: AppColors.onGold,
      ),
    );
  }
}

/// A trailer one tap away, without stealing the row's own tap.
class _TrailerButton extends StatelessWidget {
  const _TrailerButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.goldLight,
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
                color: AppColors.goldInk,
              ),
              const SizedBox(width: AppTheme.xs),
              Text(
                'Trailer',
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onGold,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
