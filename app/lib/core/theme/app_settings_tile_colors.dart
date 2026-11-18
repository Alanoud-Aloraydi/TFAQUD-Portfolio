import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// The small rounded squares behind a settings row's icon, as in iOS
/// Settings: one color per kind of care, the icon in [onTile].
abstract final class AppSettingsTileColors {
  static const Color doses = AppColors.leaf;
  static const Color measurements = AppColors.honey;
  static const Color appointments = AppColors.slateSoft;
  static const Color onTile = AppColors.inkViolet;
}
