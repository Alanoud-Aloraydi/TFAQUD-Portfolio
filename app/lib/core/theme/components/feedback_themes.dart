import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:flutter/material.dart';

/// Shared feedback themes for the current application appearance.
abstract class AppFeedbackThemes {
  AppFeedbackThemes._();

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
}
