import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/app_component_themes.dart';
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
  final VoidCallback onConfirm;
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
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
