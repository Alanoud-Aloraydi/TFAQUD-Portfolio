import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:flutter/material.dart';

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
