import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:flutter/material.dart';

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
