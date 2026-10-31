import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:flutter/material.dart';

class PickerSheetFrame extends StatelessWidget {
  const PickerSheetFrame({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    required this.child,
  });

  final String title;
  final String confirmLabel;
  /// Null turns the confirm button off.
  final VoidCallback? onConfirm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // The sheet's own drag handle comes from the bottom sheet theme;
          // a second one here drew two lines.
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
            const SizedBox(height: AppSpacing.lg),
            PillButton(label: confirmLabel, onPressed: onConfirm),
          ],
        ),
      ),
    );
  }
}
