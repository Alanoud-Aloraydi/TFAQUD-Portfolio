import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// System font, sizes from the iOS "Large" type scale. Minimum size is 12.
/// Line-height multipliers for Arabic are a design choice not yet validated on a device.
abstract class AppTextTheme {
  AppTextTheme._();

  static const double _headingHeight = 1.3;
  static const double _textHeight = 1.5;

  static const TextTheme textTheme = TextTheme(
    // Title 1, Title 2, Title 3
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: _headingHeight, color: AppColors.ink),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: _headingHeight, color: AppColors.ink),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: _headingHeight, color: AppColors.ink),
    // Headline, Callout, Subhead
    titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: _textHeight, color: AppColors.ink),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: _textHeight, color: AppColors.ink),
    titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: _textHeight, color: AppColors.ink),
    // Body, Subhead, Footnote
    bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: _textHeight, color: AppColors.ink),
    bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: _textHeight, color: AppColors.ink2),
    bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: _textHeight, color: AppColors.ink3),
    // Buttons and chips: Headline, Footnote, Caption 1
    labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: _textHeight, color: AppColors.ink),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: _textHeight, color: AppColors.ink),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: _textHeight, color: AppColors.ink3),
  );
}
