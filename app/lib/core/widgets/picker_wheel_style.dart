import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:flutter/cupertino.dart';

/// Where a wheel sits in a row of wheels.
enum WheelPosition { first, middle, last }

/// Shared look of the wheel pickers (date and time), as iOS draws them:
/// one selection band across the whole row, and the same font, size and
/// English digits in every column.
abstract class PickerWheelStyle {
  PickerWheelStyle._();

  static const double itemExtent = 44;

  static const TextStyle text = TextStyle(
    fontFamily: AppTextTheme.fontFamily,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  /// Only the outer wheels round the band's ends, so the band reads as one
  /// piece. Start and end follow the reading direction.
  static Widget overlay(WheelPosition position) {
    return CupertinoPickerDefaultSelectionOverlay(
      capStartEdge: position == WheelPosition.first,
      capEndEdge: position == WheelPosition.last,
    );
  }

  /// One wheel item: centered, in [text].
  static Widget item(String label) {
    return Center(
      child: Text(label, style: text, maxLines: 1),
    );
  }
}
