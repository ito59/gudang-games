import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/game.dart';
import '../models/game_category.dart';
import '../services/game_repository.dart';
import '../theme/app_colors.dart';
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
  bool _scrolled = false;

  late final GameRepository _repository =
      widget.repository ?? GameRepository();

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
      // back to the full list without hunting for a "show all" control.
      _selectedCategory =
          _selectedCategory == category.slug ? null : category.slug;
    });
  }

  bool _onScroll(ScrollNotification notification) {
    // Mirrors the scroll listener in code.html: the header darkens past 10px.
    // Only the outer page scroll counts, not the category strip or slider.
    if (notification.depth != 0) return false;
    final scrolled = notification.metrics.pixels > 10;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainer,
            // The header floats over the list rather than sitting in it, so
            // the spinner has to be pushed clear of it — at the default
            // offset it appears behind the wordmark.
            edgeOffset: padding.top + TopBar.height,
            child: ListView(
              padding: EdgeInsets.only(
                // main has pt-24 measured from the top of the page, and the
                // header (h-16) floats above it.
                top: padding.top + 96,
                bottom: 40 + 80 + padding.bottom,
              ),
              children: [
                HeroSlider(games: _slides, onPlay: _openGame),
                const SizedBox(height: AppTheme.xl),
                const _Gutter(child: SectionTitle('Browse Categories')),
                const SizedBox(height: AppTheme.md),
                _CategoryStrip(
                  categories: _categories,
                  selected: _selectedCategory,
                  onTap: _toggleCategory,
                ),
                const SizedBox(height: AppTheme.xl),
                const _Gutter(child: SectionTitle('Popular Games')),
                const SizedBox(height: AppTheme.md),
                _Gutter(
                  child: _PopularGames(
                    result: _result,
                    category: _selectedCategory,
                    onTap: _openGame,
                    onPlayTrailer: _openTrailer,
                    onClearCategory: () =>
                        setState(() => _selectedCategory = null),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TopBar(scrolled: _scrolled),
        ),
      ],
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrailerScreen(game: game)),
    );
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

/// Full-bleed horizontal strip (`-mx-margin-mobile px-margin-mobile`).
class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selected,
    required this.onTap,
  });

  final List<GameCategory> categories;
  final String? selected;
  final ValueChanged<GameCategory> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTheme.md),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryCard(
            category: category,
            selected: category.slug == selected,
            onTap: () => onTap(category),
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
        : result.games
              .where((game) => game.categorySlug == category)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!result.fromBackend) const _OfflineNotice(),
        if (games.isEmpty)
          _EmptyCategory(onClear: onClearCategory)
        else
          _PopularGrid(
            games: games,
            onTap: onTap,
            onPlayTrailer: onPlayTrailer,
          ),
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
          TextButton(
            onPressed: onClear,
            child: const Text('Show all games'),
          ),
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

class _PopularGrid extends StatelessWidget {
  const _PopularGrid({
    required this.games,
    required this.onTap,
    required this.onPlayTrailer,
  });

  final List<Game> games;
  final ValueChanged<Game> onTap;
  final ValueChanged<Game> onPlayTrailer;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: games.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.md,
        mainAxisSpacing: AppTheme.md,
        // Derived from the card's own metrics so it tracks the text scale.
        mainAxisExtent: GameCard.extentFor(context),
      ),
      itemBuilder: (context, index) {
        final game = games[index];
        return GameCard(
          game: game,
          onTap: () => onTap(game),
          onPlayTrailer: () => onPlayTrailer(game),
        );
      },
    );
  }
}
