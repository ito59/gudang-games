import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../models/game.dart';
import '../services/game_repository.dart';
import '../state/play_history.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/game_cover.dart';
import '../widgets/glass_panel.dart';
import '../widgets/gradient_button.dart';
import 'game_player_screen.dart';
import 'trailer_screen.dart';

/// A game's landing page.
///
/// Tapping a card lands here rather than starting the game, so somebody can
/// read what it is, watch the trailer, and then decide.
class GameDetailScreen extends StatelessWidget {
  const GameDetailScreen({super.key, required this.game, this.repository});

  final Game game;

  /// Used to count a play. Injectable so tests stay offline.
  final GameRepository? repository;

  @override
  Widget build(BuildContext context) {
    final canPlay = (game.playUrl ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _Poster(game: game),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.marginMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title, style: AppTextStyles.headlineLgMobile),
                  const SizedBox(height: AppTheme.sm),
                  _MetaRow(game: game),
                  const SizedBox(height: AppTheme.lg),
                  _Actions(
                    game: game,
                    canPlay: canPlay,
                    repository: repository,
                  ),
                  if (game.description.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.xl),
                    Text(context.tr('Tentang', 'About'), style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.primary,
                    )),
                    const SizedBox(height: AppTheme.sm),
                    Text(
                      game.description,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.xl),
                  _Stats(game: game),
                  const SizedBox(height: AppTheme.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.surfaceContainer,
      foregroundColor: AppColors.onSurface,
      // A white disc, like the reference's close button, so the arrow
      // reads over any artwork without darkening the art itself.
      leading: Padding(
        padding: const EdgeInsets.all(AppTheme.sm),
        child: IconButton.filled(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: context.tr('Kembali', 'Back'),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceContainer,
            foregroundColor: AppColors.onSurface,
            elevation: 2,
            shadowColor: AppColors.shadow,
          ),
          icon: const Icon(AppIcons.arrowBack, size: 20),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            GameCover(game: game),
            // Melts the art into the cream page below it.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0, 0.35],
                  colors: [AppColors.background, Color(0x00F7F1E5)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.sm,
      runSpacing: AppTheme.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
          ),
          child: Text(
            game.category,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimaryContainer,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.star, fill: 1, size: 16, color: AppColors.tertiary),
            const SizedBox(width: AppTheme.xs),
            Text(
              game.rating.toStringAsFixed(1),
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Text(
          context.tr(
            '${_compact(game.playsCount)} kali main',
            '${_compact(game.playsCount)} plays',
          ),
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.game,
    required this.canPlay,
    this.repository,
  });

  final Game game;
  final bool canPlay;
  final GameRepository? repository;

  Future<void> _play(BuildContext context) async {
    // The device's own history drives the Library tab; the backend count is
    // the global popularity figure. Neither is awaited — a bookkeeping
    // failure must not delay somebody playing.
    unawaited(PlayHistoryScope.of(context).record(game));
    unawaited((repository ?? GameRepository()).recordPlay(game.slug));

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GamePlayerScreen(game: game)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (canPlay)
          GradientButton(
            icon: AppIcons.playArrow,
            iconFill: 1,
            label: context.tr('Main Game', 'Play Game'),
            expand: true,
            onPressed: () => _play(context),
          )
        else
          GlassPanel(
            radius: AppTheme.radiusLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.md,
                vertical: 14,
              ),
              child: Text(
                context.tr(
                  'Game ini belum bisa dimainkan.',
                  'This game has no playable source yet.',
                ),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (game.hasTrailer) ...[
          const SizedBox(height: AppTheme.sm),
          _SecondaryButton(
            icon: AppIcons.playCircle,
            label: context.tr('Putar Trailer', 'Play Trailer'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TrailerScreen(game: game)),
            ),
          ),
        ],
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLg);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, fill: 1, size: 22, color: AppColors.primary),
                const SizedBox(width: AppTheme.sm),
                Text(
                  label,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.primary,
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

class _Stats extends StatelessWidget {
  const _Stats({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final stats = <({IconData icon, String value, String label})>[
      (icon: AppIcons.star, value: game.rating.toStringAsFixed(1), label: 'Rating'),
      (
        icon: AppIcons.bolt,
        value: _compact(game.playsCount),
        label: context.tr('Dimainkan', 'Plays'),
      ),
      (
        icon: AppIcons.videogameAsset,
        value: game.isHosted
            ? context.tr('Di server', 'Hosted')
            : context.tr('Tautan', 'Link'),
        label: context.tr('Sumber', 'Delivery'),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: AppTheme.md),
          Expanded(
            child: GlassPanel(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.md,
                  horizontal: AppTheme.sm,
                ),
                child: Column(
                  children: [
                    Icon(stats[i].icon, size: 20, color: AppColors.primary),
                    const SizedBox(height: AppTheme.sm),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        stats[i].value,
                        style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.xs),
                    Text(
                      stats[i].label,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 1234 -> 1.2k, so a long number never breaks the row.
String _compact(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return '$value';
}
