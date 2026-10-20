import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/game.dart';
import '../models/game_category.dart';
import '../services/game_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/game_card.dart';
import '../widgets/hero_slider.dart';
import '../widgets/section_title.dart';
import '../widgets/top_bar.dart';
import 'game_detail_screen.dart';
import 'trailer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.repository});

  /// Injectable so tests can drive the screen without a live backend.
  final GameRepository? repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GameRepository _repository = widget.repository ?? GameRepository();

  /// Null until the first load finishes.
  GamesResult? _result;
  List<Game> _slides = featuredGames;
  List<GameCategory> _categories = gameCategories;

  /// Slug of the category being browsed; null means everything.
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads the catalogue. Also what a pull-to-refresh runs, so the three
  /// calls go together rather than one after another — a refresh the person
  /// is watching should not cost three round trips in a row.
  Future<void> _load() async {
    final (games, slides, categories) = await (
      _repository.fetchGames(),
      _repository.fetchFeatured(),
      _repository.fetchCategories(),
    ).wait;

    if (!mounted) return;
    setState(() {
      _result = games;
      _slides = slides;
      _categories = categories;
    });
  }

  void _toggleCategory(GameCategory category) {
    setState(() {
      // Tapping the active one clears the filter, so there is always a way
      // back to the full list besides "All".
      _selectedCategory = _selectedCategory == category.slug
          ? null
          : category.slug;
    });
  }

  void _showAll() => setState(() => _selectedCategory = null);

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    // White underneath, so the sheet runs to the bottom of the screen
    // however short the list is.
    return ColoredBox(
      color: AppColors.surfaceContainer,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainer,
            edgeOffset: padding.top,
            child: ListView(
              padding: EdgeInsets.only(bottom: 40 + 80 + padding.bottom),
              children: [
                // Gold header, cream shortcut menu, white sheet: the three
                // layers of the reference's home screen.
                DecoratedBox(
                  decoration: const BoxDecoration(gradient: TopBar.gradient),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TopBar(gameCount: _result?.games.length),
                      _CategoryMenu(
                        categories: _categories,
                        selected: _selectedCategory,
                        onTap: _toggleCategory,
                        onShowAll: _showAll,
                      ),
                    ],
                  ),
                ),
                ColoredBox(
                  color: _CategoryMenu.fill,
                  child: Container(
                    padding: const EdgeInsets.only(top: AppTheme.lg),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusSheet),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HeroSlider(games: _slides, onPlay: _openGame),
                        const SizedBox(height: AppTheme.xl),
                        const _Gutter(child: SectionTitle('Popular Games')),
                        const SizedBox(height: AppTheme.md),
                        _Gutter(
                          child: _PopularGames(
                            result: _result,
                            category: _selectedCategory,
                            onTap: _openGame,
                            onPlayTrailer: _openTrailer,
                            onClearCategory: _showAll,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // The header scrolls away with the page, so the status bar needs
          // its own backing or the list runs underneath the clock.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: padding.top,
            child: const ColoredBox(color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  /// A tap lands on the game's page, not in the game. Somebody browsing
  /// should get to read about it and watch the trailer first.
  void _openGame(Game game) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameDetailScreen(game: game, repository: _repository),
      ),
    );
  }

  void _openTrailer(Game game) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TrailerScreen(game: game)));
  }
}

/// `px-margin-mobile` — the 20px page gutter.
class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
      child: child,
    );
  }
}

/// The cream shortcut panel: every category as an icon in a four-column
/// grid, led by "All", like the menu grid in `games-design.webp`.
class _CategoryMenu extends StatelessWidget {
  const _CategoryMenu({
    required this.categories,
    required this.selected,
    required this.onTap,
    required this.onShowAll,
  });

  static const fill = AppColors.surfaceContainerLow;

  static const _all = GameCategory(label: 'All', icon: AppIcons.videogameAsset);

  final List<GameCategory> categories;
  final String? selected;
  final ValueChanged<GameCategory> onTap;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.sm,
        AppTheme.md,
        AppTheme.sm,
        AppTheme.lg,
      ),
      decoration: const BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 4;
          return Wrap(
            runSpacing: AppTheme.xs,
            children: [
              SizedBox(
                width: width,
                child: CategoryCard(
                  category: _all,
                  selected: selected == null,
                  onTap: onShowAll,
                ),
              ),
              for (final category in categories)
                SizedBox(
                  width: width,
                  child: CategoryCard(
                    category: category,
                    selected: category.slug == selected,
                    onTap: () => onTap(category),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PopularGames extends StatelessWidget {
  const _PopularGames({
    required this.result,
    required this.category,
    required this.onTap,
    required this.onPlayTrailer,
    required this.onClearCategory,
  });

  final GamesResult? result;
  final String? category;
  final ValueChanged<Game> onTap;
  final ValueChanged<Game> onPlayTrailer;
  final VoidCallback onClearCategory;

  @override
  Widget build(BuildContext context) {
    final result = this.result;

    if (result == null) {
      return const _GamesMessage(text: 'Loading games…', busy: true);
    }

    if (result.games.isEmpty) {
      return const _GamesMessage(
        text: 'No published games yet.\nAdd one in the admin panel.',
      );
    }

    final games = category == null
        ? result.games
        : result.games.where((game) => game.categorySlug == category).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!result.fromBackend) const _OfflineNotice(),
        if (games.isEmpty)
          _EmptyCategory(onClear: onClearCategory)
        else
          _GameList(games: games, onTap: onTap, onPlayTrailer: onPlayTrailer),
      ],
    );
  }
}

/// A filter that matches nothing needs a way out of itself.
class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.xl),
      child: Column(
        children: [
          Text(
            'No games in this category yet.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          TextButton(onPressed: onClear, child: const Text('Show all games')),
        ],
      ),
    );
  }
}

/// Shown when the catalogue came from the bundle, not the backend, so a stale
/// list is never mistaken for live data.
class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.md,
        vertical: AppTheme.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.35)),
      ),
      child: Text(
        'Showing sample games — the server could not be reached.',
        style: AppTextStyles.labelSm.copyWith(color: AppColors.tertiary),
      ),
    );
  }
}

class _GamesMessage extends StatelessWidget {
  const _GamesMessage({required this.text, this.busy = false});

  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.xl),
      child: Column(
        children: [
          if (busy) ...[
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppTheme.md),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row per game, stacked.
class _GameList extends StatelessWidget {
  const _GameList({
    required this.games,
    required this.onTap,
    required this.onPlayTrailer,
  });

  final List<Game> games;
  final ValueChanged<Game> onTap;
  final ValueChanged<Game> onPlayTrailer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < games.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          GameCard(
            game: games[i],
            onTap: () => onTap(games[i]),
            onPlayTrailer: () => onPlayTrailer(games[i]),
          ),
        ],
      ],
    );
  }
}
