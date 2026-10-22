import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../services/game_repository.dart';
import '../state/play_history.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/game_cover.dart';
import '../widgets/glass_panel.dart';
import '../widgets/page_header.dart';
import 'game_detail_screen.dart';

/// Games this person has played, most played first.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, this.repository});

  final GameRepository? repository;

  @override
  Widget build(BuildContext context) {
    final history = PlayHistoryScope.of(context);
    final played = history.games;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      children: [
        PageHeader(title: context.tr('Koleksi', 'Library')),
        Expanded(
          child: !history.isLoaded
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : played.isEmpty
              ? const _EmptyLibrary()
              : ListView.separated(
                  padding: EdgeInsets.only(
                    left: AppTheme.marginMobile,
                    right: AppTheme.marginMobile,
                    top: AppTheme.lg,
                    bottom: 40 + 80 + bottomInset,
                  ),
                  itemCount: played.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTheme.sm),
                  itemBuilder: (context, index) => _PlayedRow(
                    entry: played[index],
                    rank: index + 1,
                    repository: repository,
                  ),
                ),
        ),
      ],
    );
  }
}

class _PlayedRow extends StatelessWidget {
  const _PlayedRow({
    required this.entry,
    required this.rank,
    this.repository,
  });

  final PlayedGame entry;
  final int rank;
  final GameRepository? repository;

  @override
  Widget build(BuildContext context) {
    final game = entry.game;

    return GlassPanel(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  GameDetailScreen(game: game, repository: repository),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMd.copyWith(
                      color: rank <= 3
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: SizedBox(
                    width: 84,
                    height: 56,
                    child: GameCover(game: game),
                  ),
                ),
                const SizedBox(width: AppTheme.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(
                          '${entry.plays} kali main'
                              ' · ${TimeFormat.relative(entry.lastPlayed)}',
                          '${entry.plays} ${entry.plays == 1 ? 'play' : 'plays'}'
                              ' · ${TimeFormat.relative(entry.lastPlayed)}',
                        ),
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.videogameAsset,
              size: 48,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppTheme.md),
            Text(
              context.tr('Belum ada yang dimainkan', 'Nothing played yet'),
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppTheme.xs),
            Text(
              context.tr(
                'Game yang kamu mainkan muncul di sini, yang paling sering dimainkan di atas.',
                'Games you play show up here, most played first.',
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
