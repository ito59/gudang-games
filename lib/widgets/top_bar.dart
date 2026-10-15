import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../state/auth_scope.dart';
import '../state/profile_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'profile_photo.dart';

/// Home header: the gold band from `games-design.webp`, rounded along its
/// bottom edge, with the wordmark in a white pill and the member's photo.
/// The shadow under it deepens once the page is scrolled.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, this.scrolled = false});

  final bool scrolled;

  static const height = 64.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      height: height + topInset,
      padding: EdgeInsets.only(
        top: topInset,
        left: AppTheme.marginMobile,
        right: AppTheme.marginMobile,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radiusSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(90, 66, 32, scrolled ? 0.22 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Align(alignment: Alignment.centerLeft, child: Wordmark()),
          ),
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
    );
  }

  /// The header band: deeper gold at the top, easing toward the cream page.
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gold, Color(0xFFE6CF9C), AppColors.goldLight],
  );
}

/// "GudangGames" in a white pill with a gold trophy, like the reference's
/// name chip. Drawn as text rather than the old violet lockup image, which
/// was made for a dark header.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
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
