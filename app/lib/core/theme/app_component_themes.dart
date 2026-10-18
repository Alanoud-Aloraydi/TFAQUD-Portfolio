import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Radius scale; the values are a design choice, not derived from a specification.
abstract class AppRadius {
  AppRadius._();

  static const double field = 12;
  static const double card = 16;
  static const double sheet = 24;
}

/// Component themes. Shared components stay plain Material widgets where
/// Material has one; they read these themes from ThemeData.
abstract class AppComponentThemes {
  AppComponentThemes._();

  /// 44 is the iOS tap target size (Design Patterns, ch. 2).
  static const Size _minButton = Size(64, 44);

  static final RoundedRectangleBorder _fieldShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.field),
  );

  static final FilledButtonThemeData filledButton = FilledButtonThemeData(
    style: FilledButton.styleFrom(minimumSize: _minButton, shape: _fieldShape),
  );

  static final OutlinedButtonThemeData outlinedButton = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: _minButton, shape: _fieldShape),
  );

  static final TextButtonThemeData textButton = TextButtonThemeData(
    style: TextButton.styleFrom(minimumSize: _minButton, shape: _fieldShape),
  );

  static OutlineInputBorder _outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Error text uses dangerInk (8.1:1): the red itself is 4.24:1 on background.
  static final InputDecorationThemeData inputDecoration = InputDecorationThemeData(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
    border: _outline(AppColors.fieldBorder),
    enabledBorder: _outline(AppColors.fieldBorder),
    focusedBorder: _outline(AppColors.brand, 2),
    errorBorder: _outline(AppColors.danger),
    focusedErrorBorder: _outline(AppColors.danger, 2),
    hintStyle: const TextStyle(color: AppColors.ink3, fontSize: 17, height: 1.5),
    errorStyle: const TextStyle(color: AppColors.dangerInk, fontSize: 13, height: 1.5),
  );

  static final ChipThemeData chip = ChipThemeData(
    backgroundColor: AppColors.surface,
    selectedColor: AppColors.brandTint,
    checkmarkColor: AppColors.brand,
    side: const BorderSide(color: AppColors.fieldBorder),
    shape: const StadiumBorder(),
    labelStyle: const TextStyle(
      color: AppColors.ink,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  static final CardThemeData card = CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: const BorderSide(color: AppColors.line),
    ),
  );

  static final DialogThemeData dialog = DialogThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sheet),
    ),
  );

  static const BottomSheetThemeData bottomSheet = BottomSheetThemeData(
    backgroundColor: AppColors.surface,
    modalBackgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    dragHandleColor: AppColors.fieldBorder,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
  );

  static final FloatingActionButtonThemeData fab = FloatingActionButtonThemeData(
    backgroundColor: AppColors.brand,
    foregroundColor: AppColors.onBrand,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    highlightElevation: 0,
    shape: const CircleBorder(),
  );

  static final AppBarThemeData appBar = AppBarThemeData(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
  );

  static const DividerThemeData divider = DividerThemeData(
    color: AppColors.line,
    thickness: 1,
    space: 1,
  );
}
