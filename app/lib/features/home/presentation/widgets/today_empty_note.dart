import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A note on «اليوم» that nothing is planned (or left), with the button
/// that opens the add sheet when [onAdd] is not null.
class TodayEmptyNote extends StatelessWidget {
  const TodayEmptyNote(this.text, {super.key, required this.onAdd});

  final String text;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: EmptyStateNote(
      text,
      actionLabel: onAdd == null ? null : context.tr('add.title'),
      onAction: onAdd,
    ),
  );
}
