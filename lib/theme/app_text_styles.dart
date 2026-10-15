import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale: Sora for display/headline/title, Hanken Grotesk for body and
/// labels.
/// Line heights are expressed as a ratio of the font size.
class AppTextStyles {
  const AppTextStyles._();

  /// 40/48, -0.02em, w700 — hero headline.
  static const displayLg = TextStyle(
    fontFamily: 'Sora',
    fontSize: 40,
    height: 48 / 40,
    letterSpacing: 40 * -0.02,
    fontWeight: FontWeight.w700,
  );

  /// 24/32, w600 — app title on mobile.
  static const headlineLgMobile = TextStyle(
    fontFamily: 'Sora',
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
  );

  /// 20/28, w500 — section headers, primary button.
  static const titleMd = TextStyle(
    fontFamily: 'Sora',
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w500,
  );

  /// 16/24, w400 — body copy.
  static const bodyMd = TextStyle(
    fontFamily: 'Hanken Grotesk',
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  /// 12/16, w500 — badges, nav and category labels. The same friendly
  /// grotesk as the body copy, as in `games-design.webp`.
  static const labelSm = TextStyle(
    fontFamily: 'Hanken Grotesk',
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
  );

  /// Card titles use the Sora face at body size, bolded (`font-title-md
  /// text-body-md font-bold` in the markup).
  static const cardTitle = TextStyle(
    fontFamily: 'Sora',
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );
}
