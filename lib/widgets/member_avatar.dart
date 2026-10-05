import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Circular avatar: the photo when one exists, otherwise tinted initials.
///
/// The design only ships one avatar image, so community members fall back to
/// initials rather than repeating the same face.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    required this.accent,
    this.image,
    this.size = 44,
    this.ring = false,
  });

  final String name;
  final Color accent;
  final String? image;
  final double size;

  /// Draws the accent ring used by the "online now" strip.
  final bool ring;

  /// Members arrive from three places: a bundled asset in the seeded data, a
  /// hosted photo from Google, or a server path this build cannot resolve.
  /// Anything but the first two falls through to initials rather than a
  /// broken image.
  Widget? _photo() {
    final source = image;
    if (source == null || source.isEmpty) return null;

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initials(),
      );
    }

    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initials(),
      );
    }

    return null;
  }

  Widget _initials() {
    return Center(
      child: Text(
        initialsOf(name),
        style: AppTextStyles.labelSm.copyWith(
          fontSize: size * 0.32,
          color: AppColors.onSurface,
        ),
      ),
    );
  }

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.22),
        border: ring ? Border.all(color: accent, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: _photo() ?? _initials(),
    );
  }
}
