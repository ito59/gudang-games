import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../models/user_profile.dart';
import '../state/auth_scope.dart';
import '../state/profile_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_panel.dart';
import '../widgets/language_sheet.dart';
import '../widgets/menu_row.dart';
import '../widgets/page_header.dart';
import '../widgets/profile_photo.dart';
import 'blocked_accounts_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProfileScope.of(context);
    final profile = controller.profile;
    final signedIn = AuthScope.of(context).isSignedIn;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      children: [
        PageHeader(title: context.tr('Profil', 'Profile')),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.load,
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainer,
            child: ListView(
              padding: EdgeInsets.only(
                top: AppTheme.lg,
                bottom: 40 + 80 + bottomInset,
              ),
              children: [
                if (!signedIn)
                  const _SignedOut()
                else if (controller.isLoading && !controller.isLive)
                  const Padding(
                    padding: EdgeInsets.all(AppTheme.xl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else ...[
                  _Identity(profile: profile),
                  const SizedBox(height: AppTheme.lg),
                  if (!controller.isLive)
                    const _Gutter(child: _CouldNotLoad())
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.marginMobile,
                      ),
                      child: GradientButton(
                        icon: AppIcons.edit,
                        label: context.tr('Edit Profil', 'Edit Profile'),
                        expand: true,
                        onPressed: () => _openEditor(context),
                      ),
                    ),
                  const SizedBox(height: AppTheme.xl),
                  _Stats(profile: profile),
                ],
                const SizedBox(height: AppTheme.xl),
                const _Menu(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final controller = ProfileScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final updatedText = context.tr('Profil diperbarui', 'Profile updated');

    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: controller.profile),
      ),
    );

    if (updated == null) return;

    final error = await controller.save(updated);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? updatedText)));
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.goldDeep, AppColors.goldLight],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(191, 154, 85, 0.35),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: ClipOval(child: ProfilePhoto(profile: profile)),
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLgMobile.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.xs),
          Text(
            '@${profile.username}',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: AppTheme.md),
            Text(
              profile.bio,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (profile.location.isNotEmpty) ...[
            const SizedBox(height: AppTheme.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  AppIcons.locationOn,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppTheme.xs),
                Text(
                  profile.location,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

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

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return _Gutter(
      child: GlassPanel(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.xl,
            horizontal: AppTheme.md,
          ),
          child: Column(
            children: [
              Icon(
                AppIcons.accountCircle,
                size: 44,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppTheme.md),
              Text(context.tr('Belum masuk', 'Not signed in'), style: AppTextStyles.cardTitle),
              const SizedBox(height: AppTheme.xs),
              Text(
                context.tr(
                  'Masuk untuk melihat dan mengedit profilmu.',
                  'Sign in to see your profile and edit it.',
                ),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.lg),
              GradientButton(
                icon: AppIcons.person,
                label: context.tr('Masuk', 'Sign in'),
                expand: true,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Signed in, but the profile did not come back from the server. Editing is
/// withheld rather than offered against placeholder data.
class _CouldNotLoad extends StatelessWidget {
  const _CouldNotLoad();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.md),
        child: Column(
          children: [
            Text(
              context.tr('Profilmu gagal dimuat', 'Your profile did not load'),
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppTheme.xs),
            Text(
              context.tr('Tarik ke bawah untuk coba lagi.', 'Pull down to try again.'),
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

class _Stats extends StatelessWidget {
  const _Stats({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final stats = <({IconData icon, String value, String label})>[
      (
        icon: AppIcons.videogameAsset,
        value: '${profile.gamesOwned}',
        label: context.tr('Game', 'Games'),
      ),
      (
        icon: AppIcons.schedule,
        value: '${profile.hoursPlayed}',
        label: context.tr('Jam', 'Hours'),
      ),
      (
        icon: AppIcons.trophy,
        value: '${profile.achievements}',
        label: context.tr('Penghargaan', 'Awards'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
      child: Row(
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
                      Icon(
                        stats[i].icon,
                        size: 20,
                        color: AppColors.primary,
                      ),
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
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu();

  /// A null `opens` means the row is still a placeholder. Account settings
  /// and Help & support stay off the list until they have screens behind
  /// them.
  static final _items =
      <({IconData icon, String labelId, String label, WidgetBuilder? opens})>[
    (
      icon: AppIcons.notifications,
      labelId: 'Notifikasi',
      label: 'Notifications',
      opens: (_) => const NotificationsScreen(),
    ),
    (
      icon: AppIcons.block,
      labelId: 'Akun diblokir',
      label: 'Blocked accounts',
      opens: (_) => const BlockedAccountsScreen(),
    ),
    (
      icon: AppIcons.privacyTip,
      labelId: 'Privasi',
      label: 'Privacy',
      opens: (_) => const PrivacyScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
      child: Column(
        children: [
          for (final item in _items) ...[
            MenuRow(
              icon: item.icon,
              label: context.tr(item.labelId, item.label),
              onTap: item.opens == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: item.opens!)),
            ),
            const SizedBox(height: AppTheme.sm),
          ],
          MenuRow(
            icon: AppIcons.language,
            label:
                '${context.tr('Bahasa', 'Language')} · ${context.language.label}',
            onTap: () => showLanguageSheet(context),
          ),
          const SizedBox(height: AppTheme.sm),
          MenuRow(
            icon: AppIcons.logout,
            label: AuthScope.of(context).isSignedIn
                ? context.tr('Keluar', 'Sign out')
                : context.tr('Masuk', 'Sign in'),
            danger: AuthScope.of(context).isSignedIn,
            onTap: () => _toggleSession(context),
          ),
        ],
      ),
    );
  }

  /// The same row signs in and out: which one it is depends on the session,
  /// and both are one tap away from the Community page that needs it.
  Future<void> _toggleSession(BuildContext context) async {
    final auth = AuthScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final signedOutText = context.tr('Kamu sudah keluar.', 'Signed out.');

    if (!auth.isSignedIn) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
      return;
    }

    await auth.signOut();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(signedOutText)));
  }
}
