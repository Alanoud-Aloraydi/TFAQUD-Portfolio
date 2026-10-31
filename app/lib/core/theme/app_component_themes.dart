import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Concentric radius scale of the design system: an inner corner equals its
/// container's radius minus the padding between them (Apple).
/// A radius-l card with 16 padding holds radius-s shapes (28 − 16 = 12);
/// with 8 padding it holds a radius-m panel (28 − 8 = 20).
abstract class AppRadius {
  AppRadius._();

  static const double l = 28; // standalone cards and grouped lists
  static const double m = 20; // nested in an l card with 8 padding
  static const double s = 12; // fields and tiles in an l card with 16 padding
  static const double xs = 4; // marks in an s shape with 8 padding

  /// Older names, kept so existing screens follow the new scale.
  static const double card = l;
  static const double field = s;
  static const double sheet = l;

  /// Rounded superellipse: the iOS corner shape (60% smoothing in Figma).
  static RoundedSuperellipseBorder shape(double radius, {BorderSide side = BorderSide.none}) {
    return RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      side: side,
    );
  }
}

/// Component themes. Shared components stay plain Material widgets where
/// Material has one; they read these themes from ThemeData.
abstract class AppComponentThemes {
  AppComponentThemes._();

  static const TextStyle _buttonLarge = TextStyle(
    fontFamily: AppTextTheme.fontFamily,
    fontSize: 17,
    height: 26 / 17,
    fontWeight: FontWeight.w600,
  );

  /// Primary: ink fill, white label, capsule, 50 high.
  static FilledButtonThemeData filledButton(AppTokens tokens) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(Size(64, AppSizes.button)),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: AppSpacing.space5),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
        textStyle: const WidgetStatePropertyAll<TextStyle>(_buttonLarge),
        elevation: const WidgetStatePropertyAll<double>(0),
        backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) return AppColors.line;
          if (states.contains(WidgetState.pressed)) return AppColors.inkPressed;
          if (states.contains(WidgetState.hovered)) return AppColors.inkHover;
          return AppColors.ink;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) return tokens.textSecondary;
          return AppColors.onInk;
        }),
        // The hover and pressed shades already show the state.
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        side: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          // Slate is only 2.05:1 on ink; the focus ring on ink is honey.
          if (states.contains(WidgetState.focused)) {
            return const BorderSide(color: AppColors.honey, width: 2);
          }
          return BorderSide.none;
        }),
      ),
    );
  }

  /// Secondary: surface fill, a 1px control border, ink label, capsule.
  static OutlinedButtonThemeData outlinedButton(AppTokens tokens) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, AppSizes.touch),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        shape: const StadiumBorder(),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        disabledForegroundColor: tokens.textSecondary,
        textStyle: const TextStyle(
          fontFamily: AppTextTheme.fontFamily,
          fontSize: 15,
          height: 22 / 15,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: tokens.borderControl),
      ),
    );
  }

  /// Plain: no fill, ink label, keeps the 44 touch height.
  static TextButtonThemeData textButton(AppTokens tokens) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, AppSizes.touch),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
        shape: const StadiumBorder(),
        foregroundColor: AppColors.ink,
        disabledForegroundColor: tokens.textSecondary,
        textStyle: const TextStyle(
          fontFamily: AppTextTheme.fontFamily,
          fontSize: 15,
          height: 22 / 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static final IconButtonThemeData iconButton = IconButtonThemeData(
    style: ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(Size(AppSizes.touch, AppSizes.touch)),
      foregroundColor: WidgetStatePropertyAll<Color>(AppColors.ink),
    ),
  );

  static OutlineInputBorder _outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.s),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Fields: 50 high, radius-s, a control border; focus and error are 2px.
  static InputDecorationThemeData inputDecoration(AppTokens tokens) {
    return InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      border: _outline(tokens.borderControl),
      enabledBorder: _outline(tokens.borderControl),
      disabledBorder: _outline(AppColors.line),
      focusedBorder: _outline(tokens.focus, 2),
      errorBorder: _outline(tokens.error, 2),
      focusedErrorBorder: _outline(tokens.error, 2),
      hintStyle: TextStyle(color: tokens.textSecondary, fontSize: 17, height: 26 / 17),
      labelStyle: TextStyle(color: tokens.textSecondary, fontSize: 15, height: 22 / 15),
      floatingLabelStyle: const TextStyle(color: AppColors.ink, fontSize: 15, height: 22 / 15),
      helperStyle: TextStyle(color: tokens.textSecondary, fontSize: 13, height: 20 / 13),
      errorStyle: TextStyle(color: tokens.errorText, fontSize: 13, height: 20 / 13),
      prefixIconColor: tokens.textSecondary,
      suffixIconColor: tokens.textSecondary,
    );
  }

  static ChipThemeData chip(AppTokens tokens) {
    return ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.honeyTint,
      checkmarkColor: AppColors.ink,
      disabledColor: AppColors.line,
      side: BorderSide(color: tokens.borderControl),
      shape: const StadiumBorder(),
      showCheckmark: true,
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Opaque cards on canvas: surface, radius-l, a soft ink shadow.
  static final CardThemeData card = CardThemeData(
    color: AppColors.surface,
    elevation: 1,
    shadowColor: const Color(0x33202734),
    margin: EdgeInsets.zero,
    surfaceTintColor: Colors.transparent,
    shape: AppRadius.shape(AppRadius.l),
  );

  static final DialogThemeData dialog = DialogThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    shape: AppRadius.shape(AppRadius.l),
  );

  static final BottomSheetThemeData bottomSheet = BottomSheetThemeData(
    backgroundColor: AppColors.surface,
    modalBackgroundColor: AppColors.surface,
    modalBarrierColor: AppColors.scrim,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    dragHandleColor: AppColors.stone,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
    ),
  );

  /// Any other floating action button follows the primary action.
  static final FloatingActionButtonThemeData fab = FloatingActionButtonThemeData(
    backgroundColor: AppColors.ink,
    foregroundColor: AppColors.onInk,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    highlightElevation: 0,
    shape: CircleBorder(),
  );

  /// Bars carry no background or divider: glass controls float on canvas.
  static final AppBarThemeData appBar = AppBarThemeData(
    backgroundColor: AppColors.canvas,
    foregroundColor: AppColors.ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: AppTextTheme.fontFamily,
      color: AppColors.ink,
      fontSize: 17,
      height: 26 / 17,
      fontWeight: FontWeight.w600,
    ),
  );

  static final DividerThemeData divider = DividerThemeData(
    color: AppColors.line,
    thickness: 1,
    space: 1,
  );

  static final ProgressIndicatorThemeData progress = ProgressIndicatorThemeData(
    color: AppColors.ink,
    linearTrackColor: AppColors.line,
    circularTrackColor: Colors.transparent,
  );

  static final SnackBarThemeData snackBar = SnackBarThemeData(
    backgroundColor: AppColors.ink,
    contentTextStyle: TextStyle(
      fontFamily: AppTextTheme.fontFamily,
      color: AppColors.surface,
      fontSize: 15,
      height: 22 / 15,
    ),
    behavior: SnackBarBehavior.floating,
    shape: StadiumBorder(),
  );

  static ListTileThemeData listTile(AppTokens tokens) {
    return ListTileThemeData(
      iconColor: tokens.textSecondary,
      textColor: AppColors.ink,
      minTileHeight: AppSizes.touch,
      shape: AppRadius.shape(AppRadius.s),
    );
  }

  static final CheckboxThemeData checkbox = CheckboxThemeData(
    checkColor: WidgetStatePropertyAll<Color>(AppColors.surface),
    side: BorderSide(color: AppColors.stone, width: 1.5),
  );

  static final RadioThemeData radio = RadioThemeData(
    fillColor: WidgetStatePropertyAll<Color>(AppColors.ink),
  );
}
