import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/revision_entry_lines.dart';
import 'package:flutter/material.dart';

/// One version of a medicine as a card, the same for every step of «سجل
/// التعديلات» and for the change that waits for its day: the [title], an
/// optional [note] under it, the medicine as [version] has it (what changed
/// from [previous] crossed out), read as one sentence, then an [action].
class MedicationVersionCard extends StatelessWidget {
  const MedicationVersionCard({
    super.key,
    required this.title,
    required this.version,
    required this.previous,
    this.note,
    this.action,
  });

  final String title;
  final MedicationVersion version;
  final MedicationVersion? previous;
  final String? note;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: AppTextTheme.bold,
                  ),
                ),
                if (note case final String note)
                  Text(
                    note,
                    style: text.bodySmall?.copyWith(
                      color: context.tokens.textSecondary,
                    ),
                  ),
                RevisionEntryLines(version: version, previous: previous),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
