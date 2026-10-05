import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/user_profile.dart';
import '../state/auth_scope.dart';
import '../state/profile_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'profile_photo.dart';

/// `<header>`: fixed, `bg-surface/80`, `backdrop-blur-xl`, h-16,
/// with a violet drop shadow that deepens once the page is scrolled.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, this.scrolled = false});

  final bool scrolled;

  static const height = 64.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: height + topInset,
          padding: EdgeInsets.only(
            top: topInset,
            left: AppTheme.marginMobile,
            right: AppTheme.marginMobile,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: scrolled ? 0.95 : 0.80),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(115, 46, 228, 0.15),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // The brand lockup replaces the wordmark text so the header
              // matches the launcher icon exactly. The semantics label keeps
              // the name available to screen readers and to widget tests.
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    label: 'BandarGames',
                    image: true,
                    child: Image.asset(
                      brandLockup,
                      height: 34,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
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
        ),
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
