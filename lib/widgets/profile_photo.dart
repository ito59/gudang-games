import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// The signed-in member's own photo.
///
/// One they uploaded wins, then the one their Google account came with, and
/// the bundled art stands in when they have neither — including for a photo
/// that fails to load, which would otherwise leave a hole where a face was.
///
/// A null [profile] means nobody is signed in, and draws an anonymous mark
/// instead. That distinction matters: the bundled art is a whole invented
/// member, and showing their face to a signed-out visitor tells them they
/// are logged in as somebody.
///
/// Shared rather than written per screen: the header, the profile page and
/// the editor all show the same person and must agree about which picture
/// that is.
class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({super.key, required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;

    if (profile == null) {
      return const ColoredBox(
        color: AppColors.surfaceContainerHigh,
        child: Center(
          child: Icon(
            AppIcons.accountCircle,
            size: 26,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    final url = profile.avatarUrl;

    if (url == null || url.isEmpty) {
      return Image.asset(profile.avatar, fit: BoxFit.cover);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(profile.avatar, fit: BoxFit.cover),
    );
  }
}
