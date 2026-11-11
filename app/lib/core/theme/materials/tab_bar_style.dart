import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Colours and timing of a tab bar that is transparent at rest and dark only
/// while a finger is on it. Ink and white give 14:1 contrast in both states.
abstract class AppTabBarStyle {
  AppTabBarStyle._();

  static const Color restFill = Color(0x00FFFFFF);
  static const Color pressedFill = AppColors.ink;
  static const Color pressedForeground = Color(0xFFFFFFFF);
  static const Color pressedMutedForeground = Color(0xB3FFFFFF);
  static const Duration transition = Duration(milliseconds: 160);
}
