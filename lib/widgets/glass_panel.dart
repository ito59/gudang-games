import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The `.glass-panel` rule from `code.html`:
///
/// ```css
/// background: rgba(30, 41, 59, 0.4);
/// backdrop-filter: blur(12px);
/// border: 1px solid rgba(255, 255, 255, 0.05);
/// box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.1);
/// ```
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = AppTheme.radiusXl,
    this.neonGlow = false,
  });

  final Widget child;
  final double radius;

  /// `.neon-glow`: `0 0 15px rgba(210, 187, 255, 0.15)`.
  final bool neonGlow;

  static const fill = Color.fromRGBO(30, 41, 59, 0.4);
  static const borderColor = Color.fromRGBO(255, 255, 255, 0.05);
  static const highlight = Color.fromRGBO(255, 255, 255, 0.1);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
        boxShadow: neonGlow
            ? const [
                BoxShadow(
                  color: Color.fromRGBO(210, 187, 255, 0.15),
                  blurRadius: 15,
                ),
              ]
            : null,
      ),
      child: Stack(
        // passthrough hands the panel's own constraints to the content.
        // Without it the child is laid out loose, shrinks to its intrinsic
        // width and sits against the top-left corner instead of filling.
        fit: StackFit.passthrough,
        children: [
          ClipRRect(borderRadius: borderRadius, child: child),
          // inset 0 1px 0 — a hairline highlight along the top edge.
          Positioned(
            top: 0,
            left: radius / 2,
            right: radius / 2,
            child: const SizedBox(
              height: 1,
              child: ColoredBox(color: highlight),
            ),
          ),
        ],
      ),
    );
  }
}
