import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_effects.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/overlays/app_alert_action.dart';
import 'package:flutter/material.dart';

/// The capsule button of one [AppAlertAction]; tapping it closes the alert
/// with the action's value.
class AppAlertButton<T> extends StatelessWidget {
  const AppAlertButton({super.key, required this.action});

  final AppAlertAction<T> action;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(action.label, textAlign: TextAlign.center);
    void tap() => Navigator.of(context).pop(action.value);
    const Size size = Size.fromHeight(AppSizes.compactButton);
    if (action.primary && !action.destructive) {
      return FilledButton(
        onPressed: tap,
        style: FilledButton.styleFrom(minimumSize: size),
        child: label,
      );
    }
    return FilledButton(
      onPressed: tap,
      style:
          FilledButton.styleFrom(
            minimumSize: size,
            backgroundColor: AppSemanticColors.borderSubtle,
            foregroundColor: action.destructive
                ? context.tokens.errorText
                : AppSemanticColors.textPrimary,
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll<Color>(
              AppEffects.interactionOverlay,
            ),
          ),
      child: label,
    );
  }
}
