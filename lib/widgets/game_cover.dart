import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Draws a game's artwork, wherever it comes from.
///
/// Covers may be bundled with the app, served by the backend, or missing
/// entirely — a game uploaded without one still has to look deliberate.
class GameCover extends StatelessWidget {
  const GameCover({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    if (!game.hasImage) {
      return const _Placeholder();
    }

    if (game.imageIsRemote) {
      return Image.network(
        game.image,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const _Placeholder(loading: true),
        errorBuilder: (context, error, stack) => const _Placeholder(),
      );
    }

    return Image.asset(
      game.image,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1B4D), Color(0xFF131B2E)],
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                AppIcons.videogameAsset,
                size: 32,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
      ),
    );
  }
}
