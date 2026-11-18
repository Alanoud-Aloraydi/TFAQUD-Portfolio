import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// The welcome pages: the page behind the pictures, the soft glows on it
/// (two per page: warm honey, light leaf, and a calm grey blue on the
/// last), and the dots of the pages not on show.
abstract final class AppIntroColors {
  static const Color canvas = AppColors.canvas;
  static const Color glowWarm = AppColors.honeyBorder;
  static const Color glowLeaf = AppColors.leafTint;
  static const Color glowMist = AppColors.slatePale;
  static const Color glowCalm = AppColors.slateMist;
  static const Color dotIdle = AppColors.slateSoft;
}
