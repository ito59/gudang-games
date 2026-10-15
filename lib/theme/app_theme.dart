import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  /// Spacing scale.
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const marginMobile = 20.0;

  /// borderRadius scale. Rounder than the old cyber look: the reference is
  /// all soft cards and pill buttons.
  static const radiusDefault = 6.0;
  static const radiusLg = 12.0;
  static const radiusXl = 18.0;

  /// Bottom sheets and dialogs.
  static const radiusSheet = 28.0;

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimaryContainer,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.goldDeep,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outline: AppColors.outlineVariant,
        outlineVariant: AppColors.outlineVariant,
        // Dark ink on a cream page: the snackbar and tooltips stay readable.
        inverseSurface: AppColors.onSurface,
        onInverseSurface: AppColors.primaryFixed,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.outlineVariant),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onPrimaryContainer
              : AppColors.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surfaceContainerHighest,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.onSurface,
        contentTextStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.primaryFixed,
        ),
        actionTextColor: AppColors.gold,
        closeIconColor: AppColors.goldLight,
        insetPadding: const EdgeInsets.all(md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Color.fromRGBO(40, 28, 12, 0.55),
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSheet),
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
          textStyle: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color.fromRGBO(217, 188, 128, 0.45),
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
