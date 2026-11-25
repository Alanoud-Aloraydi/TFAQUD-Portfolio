import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/app_tokens_presets.dart';
import 'package:app/core/theme/components/button_themes.dart';
import 'package:app/core/theme/components/navigation_themes.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The TFAQUD theme (design system "TFAQUD"): light only, plus the variant the
/// app uses when iOS Increase Contrast is on.
///
/// [ColorScheme.primary] is ink: Material paints text, icons, selection marks
/// in it. Filled actions have their own green brand roles so inline text
/// and small selection marks retain readable contrast.
abstract class AppTheme {
  AppTheme._();

  static ThemeData _build(AppTokens tokens) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextTheme.fontFamily,
      colorScheme: buildAppColorScheme(tokens),
      scaffoldBackgroundColor: AppSemanticColors.background,
      canvasColor: AppSemanticColors.background,
      textTheme: AppTextTheme.build(secondary: tokens.textSecondary),
      extensions: <ThemeExtension<dynamic>>[tokens],
      filledButtonTheme: AppButtonThemes.filledButton(tokens),
      outlinedButtonTheme: AppButtonThemes.outlinedButton(tokens),
      textButtonTheme: AppButtonThemes.textButton(tokens),
      iconButtonTheme: AppButtonThemes.iconButton,
      inputDecorationTheme: AppFieldThemes.inputDecoration(tokens),
      chipTheme: AppSelectionThemes.chip(tokens),
      cardTheme: AppSurfaceThemes.card,
      dialogTheme: AppSurfaceThemes.dialog,
      bottomSheetTheme: AppSurfaceThemes.bottomSheet,
      dividerTheme: AppSurfaceThemes.divider,
      appBarTheme: AppNavigationThemes.appBar,
      floatingActionButtonTheme: AppButtonThemes.fab,
      progressIndicatorTheme: AppFeedbackThemes.progress,
      snackBarTheme: AppFeedbackThemes.snackBar,
      listTileTheme: AppSurfaceThemes.listTile(tokens),
      checkboxTheme: AppSelectionThemes.checkbox(tokens),
      radioTheme: AppSelectionThemes.radio,
      // iOS shows a press as a short dim, not a ripple.
      splashFactory: NoSplash.splashFactory,
      // iOS push and pop (with the swipe back) on every platform, the web
      // preview included, so testing in Chrome feels like the phone.
      pageTransitionsTheme: iosPageTransitions,
      // The back and close buttons Material draws by itself (the app bar of
      // a medicine's pages) use Apple's symbols, as every icon in the app.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (BuildContext context) =>
            const Icon(ArrowIcons.back),
        closeButtonIconBuilder: (BuildContext context) =>
            const Icon(ActionIcons.x),
      ),
      // Cupertino widgets (pickers, action sheets, dialogs) use the app font
      // and ink instead of the system blue.
      cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
        primaryColor: AppSemanticColors.textPrimary,
        scaffoldBackgroundColor: AppSemanticColors.background,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppSemanticColors.textPrimary,
          pickerTextStyle: AppTextTheme.picker,
          dateTimePickerTextStyle: AppTextTheme.picker,
        ),
      ),
      highlightColor: AppEffects.interactionOverlay,
    );
  }

  static final ThemeData lightTheme = _build(AppTokens.light);

  /// Used by MaterialApp when iOS Increase Contrast is on: secondary text and
  /// status words turn ink, control borders turn slate.
  static final ThemeData highContrastTheme = _build(AppTokens.contrast);
}

/// iOS push and pop on every platform.
const PageTransitionsTheme iosPageTransitions = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
  },
);

/// Shared field themes for the current application appearance.
abstract class AppFieldThemes {
  AppFieldThemes._();

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
      fillColor: AppSemanticColors.surfaceContent,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      border: _outline(tokens.borderControl),
      enabledBorder: _outline(tokens.borderControl),
      disabledBorder: _outline(AppSemanticColors.borderSubtle),
      focusedBorder: _outline(tokens.focus, 2),
      errorBorder: _outline(tokens.error, 2),
      focusedErrorBorder: _outline(tokens.error, 2),
      // Every style names the app font: a component style that leaves it out
      // can fall back to the system font.
      hintStyle: TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: tokens.textSecondary,
        fontSize: 17,
        height: 28 / 17,
      ),
      labelStyle: TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: tokens.textSecondary,
        fontSize: 15,
        height: 24 / 15,
      ),
      floatingLabelStyle: const TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: AppSemanticColors.textPrimary,
        fontSize: 15,
        height: 24 / 15,
      ),
      helperStyle: TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: tokens.textSecondary,
        fontSize: 13,
        height: 20 / 13,
      ),
      errorStyle: TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: tokens.errorText,
        fontSize: 13,
        height: 20 / 13,
      ),
      prefixIconColor: tokens.textSecondary,
      suffixIconColor: tokens.textSecondary,
    );
  }
}

/// Shared feedback themes for the current application appearance.
abstract class AppFeedbackThemes {
  AppFeedbackThemes._();

  static final ProgressIndicatorThemeData progress = ProgressIndicatorThemeData(
    color: AppSemanticColors.textPrimary,
    linearTrackColor: AppSemanticColors.borderSubtle,
    circularTrackColor: Colors.transparent,
  );

  static final SnackBarThemeData snackBar = SnackBarThemeData(
    backgroundColor: AppSemanticColors.textPrimary,
    contentTextStyle: TextStyle(
      fontFamily: AppTextTheme.fontFamily,
      color: AppSemanticColors.surfaceContent,
      fontSize: 15,
      height: 24 / 15,
    ),
    behavior: SnackBarBehavior.floating,
    shape: StadiumBorder(),
  );
}

/// Shared surface themes for the current application appearance.
abstract class AppSurfaceThemes {
  AppSurfaceThemes._();

  /// Opaque cards on canvas: surface, radius-l, a 1px line edge, no shadow.
  static final CardThemeData card = CardThemeData(
    color: AppSemanticColors.surfaceContent,
    elevation: 0,
    margin: EdgeInsets.zero,
    surfaceTintColor: Colors.transparent,
    shape: AppRadius.shape(AppRadius.l, side: AppSurfaces.edge),
  );

  static final DialogThemeData dialog = DialogThemeData(
    backgroundColor: AppSemanticColors.surfaceContent,
    surfaceTintColor: Colors.transparent,
    barrierColor: AppSemanticColors.overlayScrim,
    shape: AppRadius.shape(AppRadius.l),
  );

  static final BottomSheetThemeData bottomSheet = BottomSheetThemeData(
    backgroundColor: AppSemanticColors.surfaceContent,
    modalBackgroundColor: AppSemanticColors.surfaceContent,
    modalBarrierColor: AppSemanticColors.overlayScrim,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    dragHandleColor: AppSemanticColors.borderControlBase,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
    ),
  );

  static final DividerThemeData divider = DividerThemeData(
    color: AppSemanticColors.borderSubtle,
    thickness: 1,
    space: 1,
  );

  static ListTileThemeData listTile(AppTokens tokens) {
    return ListTileThemeData(
      iconColor: tokens.textSecondary,
      textColor: AppSemanticColors.textPrimary,
      minTileHeight: AppSizes.touch,
      shape: AppRadius.shape(AppRadius.s),
    );
  }
}

/// Shared selection themes for the current application appearance.
abstract class AppSelectionThemes {
  AppSelectionThemes._();

  static ChipThemeData chip(AppTokens tokens) {
    return ChipThemeData(
      backgroundColor: AppSemanticColors.surfaceContent,
      selectedColor: AppSemanticColors.selectedSurface,
      checkmarkColor: AppSemanticColors.textPrimary,
      disabledColor: AppSemanticColors.borderSubtle,
      // A chosen chip's line is a deeper shade of its own violet fill,
      // not a grey ruled around it. An unchosen chip is white, so it
      // keeps the control grey that makes it read as a thing to press.
      side: WidgetStateBorderSide.resolveWith(
        (Set<WidgetState> states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? AppSemanticColors.selectedSurface
              : tokens.borderControl,
        ),
      ),
      shape: const StadiumBorder(),
      showCheckmark: true,
      // The chip theme's label style replaces Material's default, so it must
      // name the app font itself; without it the options of «الأمراض
      // المزمنة» and «الحساسية» showed in the system font.
      labelStyle: const TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: AppSemanticColors.textPrimary,
        fontSize: 15,
        height: 24 / 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static CheckboxThemeData checkbox(AppTokens tokens) => CheckboxThemeData(
    checkColor: WidgetStatePropertyAll<Color>(AppSemanticColors.surfaceContent),
    side: BorderSide(color: tokens.borderControl, width: 1.5),
  );

  static final RadioThemeData radio = RadioThemeData(
    fillColor: WidgetStatePropertyAll<Color>(AppSemanticColors.textPrimary),
  );
}
