import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:flutter/cupertino.dart';

/// What a picker puts in its glass sheet (`showGlassSheet`, which draws the
/// title): the wheels, then the confirm button.
class PickerSheetFrame extends StatelessWidget {
  const PickerSheetFrame({
    super.key,
    required this.confirmLabel,
    required this.onConfirm,
    required this.child,
  });

  final String confirmLabel;

  /// Null turns the confirm button off.
  final VoidCallback? onConfirm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: AppSpacing.lg),
        PillButton(label: confirmLabel, onPressed: onConfirm),
      ],
    );
  }
}

/// Where a wheel sits in a row of wheels.
enum WheelPosition { first, middle, last }

/// Shared look of the wheel pickers (date and time), as iOS draws them:
/// one selection band across the whole row, and the same font, size and
/// English digits in every column.
abstract class PickerWheelStyle {
  PickerWheelStyle._();

  static const double itemExtent = AppSizes.touch;

  static const TextStyle text = AppTextTheme.picker;

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
    return Center(child: Text(label, style: text, maxLines: 1));
  }
}
