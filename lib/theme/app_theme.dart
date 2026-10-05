import 'package:flutter/material.dart';

import '../widgets/glass_panel.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  /// Spacing scale from `code.html`.
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const marginMobile = 20.0;

  /// borderRadius scale: DEFAULT 4, lg 8, xl 12.
  static const radiusDefault = 4.0;
  static const radiusLg = 8.0;
  static const radiusXl = 12.0;

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outlineVariant: AppColors.outlineVariant,
      ),
      // Material 3 defaults these to `inverseSurface`, which is a LIGHT colour
      // in a dark scheme — a white slab over the cyber UI. Theme them here so
      // no call site has to remember.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceContainerHigh,
        contentTextStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.onSurface,
        ),
        actionTextColor: AppColors.primary,
        closeIconColor: AppColors.onSurfaceVariant,
        insetPadding: const EdgeInsets.all(md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: GlassPanel.borderColor),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Color.fromRGBO(0, 0, 0, 0.6),
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: AppTextStyles.titleMd.copyWith(
          color: AppColors.onSurface,
        ),
        contentTextStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color.fromRGBO(210, 187, 255, 0.3),
        selectionHandleColor: AppColors.primary,
      ),
      textTheme: base.textTheme
          .copyWith(
            displayLarge: AppTextStyles.displayLg,
            headlineLarge: AppTextStyles.headlineLgMobile,
            titleMedium: AppTextStyles.titleMd,
            bodyMedium: AppTextStyles.bodyMd,
            labelSmall: AppTextStyles.labelSm,
          )
          .apply(
            bodyColor: AppColors.onBackground,
            displayColor: AppColors.onBackground,
          ),
    );
  }
}
