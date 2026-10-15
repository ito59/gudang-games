import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The card every panel in the app sits on: white on the cream page, a
/// hairline warm border and a soft drop shadow, as in `games-design.webp`.
///
/// The name is kept from the earlier frosted-glass look so call sites did not
/// have to change.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = AppTheme.radiusXl,
    this.neonGlow = false,
  });

  final Widget child;
  final double radius;

  /// Marks the panel as selected: a gold outline and a warmer glow.
  final bool neonGlow;

  static const fill = AppColors.surfaceContainer;
  static const borderColor = Color(0xFFEDE3D0);

  static const _shadow = BoxShadow(
    color: Color.fromRGBO(90, 66, 32, 0.08),
    blurRadius: 18,
    offset: Offset(0, 6),
  );

  static const _glow = BoxShadow(
    color: Color.fromRGBO(191, 154, 85, 0.35),
    blurRadius: 18,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: Border.all(
          color: neonGlow ? AppColors.goldDeep : borderColor,
          width: neonGlow ? 1.5 : 1,
        ),
        boxShadow: [neonGlow ? _glow : _shadow],
      ),
      // The child is clipped to the rounded corners so artwork does not
      // poke out past them. passthrough hands the panel's own constraints to
      // the content; without it the child is laid out loose and shrinks.
      child: Stack(
        fit: StackFit.passthrough,
        children: [ClipRRect(borderRadius: borderRadius, child: child)],
      ),
    );
  }
}
