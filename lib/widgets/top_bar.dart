import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../models/user_profile.dart';
import '../state/auth_scope.dart';
import '../state/profile_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'profile_photo.dart';

/// Home header: the tall gold band from `games-design.webp`. The wordmark
/// chip, a "current balance"-style chip counting the games on offer, and the
/// member's photo sit on one row, with a greeting below them.
///
/// It scrolls with the page rather than floating over it, so the category
/// panel underneath can sit flush against it.
class TopBar extends StatelessWidget {
  const TopBar({super.key, this.gameCount});

  /// Null while the catalogue is still loading.
  final int? gameCount;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.marginMobile,
        topInset + AppTheme.sm,
        AppTheme.marginMobile,
        AppTheme.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Align(alignment: Alignment.centerLeft, child: Wordmark()),
              ),
              const SizedBox(width: AppTheme.sm),
              _GamesChip(count: gameCount),
              const SizedBox(width: AppTheme.sm),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceContainer, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(90, 66, 32, 0.18),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                // Only once the member's own profile has actually arrived.
                // Signed out, the controller still holds the bundled sample
                // member, and drawing their face here would tell a visitor
                // they are logged in as somebody.
                child: ProfilePhoto(profile: _signedInProfile(context)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.lg),
          Text(
            context.tr('Siap main?', 'Ready to play?'),
            style: AppTextStyles.headlineLgMobile.copyWith(
              color: AppColors.onGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.xs),
          Text(
            context.tr(
              'Pilih kategori atau langsung main game unggulan hari ini.',
              'Pick a category or jump into today\'s featured game.',
            ),
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 14,
              height: 20 / 14,
              color: AppColors.onGold.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }

  /// The header band: deeper gold at the top, easing toward the cream page.
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gold, Color(0xFFE6CF9C), AppColors.goldLight],
  );
}

/// The reference's "Current balance" chip, counting games instead of money.
class _GamesChip extends StatelessWidget {
  const _GamesChip({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              AppIcons.videogameAsset,
              fill: 1,
              size: 20,
              color: AppColors.goldDeep,
            ),
          ),
          const SizedBox(width: AppTheme.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('Game', 'Games'),
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 11,
                  height: 14 / 11,
                  color: AppColors.onGold.withValues(alpha: 0.7),
                ),
              ),
              Text(
                count?.toString() ?? '–',
                style: AppTextStyles.cardTitle.copyWith(
                  height: 20 / 16,
                  color: AppColors.onGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "GudangGames" in a white pill with a gold trophy, like the reference's
/// name chip. Drawn as text rather than the old violet lockup image, which
/// was made for a dark header.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Its own node, so screen readers do not run the brand into the
      // games count and greeting beside it.
      container: true,
      label: 'GudangGames',
      excludeSemantics: true,
      // Shrinks rather than overflows when a large text setting would push
      // the name past the space beside the avatar.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: _pill(),
      ),
    );
  }

  Widget _pill() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(90, 66, 32, 0.12),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            AppIcons.trophy,
            fill: 1,
            size: 20,
            color: AppColors.goldDeep,
          ),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(
              children: const [
                TextSpan(text: 'Gudang'),
                TextSpan(
                  text: 'Games',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
              style: AppTextStyles.titleMd.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.onSurface,
              ),
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

/// The member's profile, or null when nobody is signed in.
UserProfile? _signedInProfile(BuildContext context) {
  if (!AuthScope.of(context).isSignedIn) return null;

  final controller = ProfileScope.of(context);
  return controller.isLive ? controller.profile : null;
}
