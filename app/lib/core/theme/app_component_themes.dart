import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Concentric radius scale of the design system: an inner corner equals its
/// container's radius minus the padding between them (Apple).
/// A radius-l card with 16 padding holds radius-s shapes (28 − 16 = 12);
/// with 8 padding it holds a radius-m panel (28 − 8 = 20).
abstract class AppRadius {
  AppRadius._();

  /// Alerts: a 48 capsule button 12 inside the panel (24 + 12).
  static const double xl = 36;
  static const double l = 28; // standalone cards and grouped lists
  static const double m = 20; // nested in an l card with 8 padding
  static const double s = 12; // fields and tiles in an l card with 16 padding
  static const double xs = 4; // marks in an s shape with 8 padding

  /// Capsules: the radius is half the height (design system radius-capsule).
  static const double capsule = 999;

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

/// The app's opaque card (design system Card): surface, the iOS smooth
/// corner, and a 1px `line` edge in place of a shadow. Cards on the canvas
/// need an edge (surface is only 1.07:1 there); a thin line is lighter and
/// crisper than a blurred shadow.
abstract class AppSurfaces {
  AppSurfaces._();

  static const BorderSide edge = BorderSide(color: AppColors.line);

  static ShapeBorder cardShape([double radius = AppRadius.card]) =>
      AppRadius.shape(radius, side: edge);

  static ShapeDecoration card([double radius = AppRadius.card]) =>
      ShapeDecoration(color: AppColors.surface, shape: cardShape(radius));
}

/// Component themes. Shared components stay plain Material widgets where
/// Material has one; they read these themes from ThemeData.
abstract class AppComponentThemes {
  AppComponentThemes._();

  static const TextStyle _buttonLarge = TextStyle(
    fontFamily: AppTextTheme.fontFamily,
    fontSize: 17,
    height: 28 / 17,
    fontWeight: FontWeight.w600,
  );

  /// Primary: ink fill, white label, capsule, 48 high.
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
          // Pressed (and pointer hover) lightens to slate, the next navy of
          // the palette; the white label stays 10.19:1.
          if (states.contains(WidgetState.pressed)) return AppColors.slate;
          if (states.contains(WidgetState.hovered)) return AppColors.slate;
          return AppColors.ink;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) return tokens.textSecondary;
          return AppColors.onInk;
        }),
        // The pressed shade already shows the state.
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        side: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          // Slate is only 1.47:1 on ink; the focus ring on ink is honey.
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
          height: 24 / 15,
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
          height: 24 / 15,
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

  /// Fields: 52 high (a 28 line, 12 above and below), radius-s, a control
  /// border; focus and error are 2px.
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
      // Every style names the app font: a component style that leaves it out
      // can fall back to the system font.
      hintStyle: TextStyle(fontFamily: AppTextTheme.fontFamily, color: tokens.textSecondary, fontSize: 17, height: 28 / 17),
      labelStyle: TextStyle(fontFamily: AppTextTheme.fontFamily, color: tokens.textSecondary, fontSize: 15, height: 24 / 15),
      floatingLabelStyle: const TextStyle(fontFamily: AppTextTheme.fontFamily, color: AppColors.ink, fontSize: 15, height: 24 / 15),
      helperStyle: TextStyle(fontFamily: AppTextTheme.fontFamily, color: tokens.textSecondary, fontSize: 13, height: 20 / 13),
      errorStyle: TextStyle(fontFamily: AppTextTheme.fontFamily, color: tokens.errorText, fontSize: 13, height: 20 / 13),
      prefixIconColor: tokens.textSecondary,
      suffixIconColor: tokens.textSecondary,
    );
  }

  static ChipThemeData chip(AppTokens tokens) {
    return ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.leafTint,
      checkmarkColor: AppColors.ink,
      disabledColor: AppColors.line,
      side: BorderSide(color: tokens.borderControl),
      shape: const StadiumBorder(),
      showCheckmark: true,
      // The chip theme's label style replaces Material's default, so it must
      // name the app font itself; without it the options of «الأمراض
      // المزمنة» and «الحساسية» showed in the system font.
      labelStyle: const TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: AppColors.ink,
        fontSize: 15,
        height: 24 / 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Opaque cards on canvas: surface, radius-l, a 1px line edge, no shadow.
  static final CardThemeData card = CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    surfaceTintColor: Colors.transparent,
    shape: AppRadius.shape(AppRadius.l, side: AppSurfaces.edge),
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
    // Dark status bar text (time, signal, battery) on the light canvas. A
    // transparent bar would otherwise get white text that cannot be seen.
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: TextStyle(
      fontFamily: AppTextTheme.fontFamily,
      color: AppColors.ink,
      fontSize: 17,
      height: 28 / 17,
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
      height: 24 / 15,
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
