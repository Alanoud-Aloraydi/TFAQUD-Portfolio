import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/medications/presentation/widgets/dose_snooze_label.dart';
import 'package:flutter/material.dart';

/// The «ذكّرني لاحقًا» button itself: the compact [style] of the row it
/// sits in, in the quiet surface colours so it does not read as the
/// answer beside it.
Widget doseSnoozeFace(
  BuildContext context, {
  required ButtonStyle style,
  required DateTime? at,
  required SharedSnooze? shared,
  required VoidCallback onPressed,
}) => FilledButton.tonalIcon(
  style: style.copyWith(
    backgroundColor: const WidgetStatePropertyAll<Color>(
      AppSemanticColors.surfaceContent,
    ),
    foregroundColor: const WidgetStatePropertyAll<Color>(
      AppSemanticColors.textPrimary,
    ),
  ),
  onPressed: onPressed,
  icon: Icon(doseSnoozeIcon(at, shared), size: 16),
  label: Text(doseSnoozeLabel(context, at, shared)),
);
