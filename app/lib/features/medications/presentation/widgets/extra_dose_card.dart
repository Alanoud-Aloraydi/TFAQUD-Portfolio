import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_history_entry.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_lines.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// An extra dose in «سجل الجرعات», drawn as the other doses are: the time
/// it was taken above the medicine with its strength and dose, and in the
/// corner «إضافية» with who recorded it.
class ExtraDoseCard extends StatelessWidget {
  const ExtraDoseCard({super.key, required this.entry, this.circleId});

  final ExtraDoseEntry entry;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: ExtraDoseLines(entry: entry)),
            const SizedBox(width: AppSpacing.sm),
            ExtraDoseOutcome(dose: entry.dose, circleId: circleId),
          ],
        ),
      ),
    ),
  );
}

/// The corner of an extra dose in the history, where the other doses say
/// what became of them: «إضافية», with who recorded it centred under it.
class ExtraDoseOutcome extends StatelessWidget {
  const ExtraDoseOutcome({super.key, required this.dose, this.circleId});

  final ExtraDose dose;

  /// Needed to show who recorded it; null leaves the pill alone.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final String? name = dose.recordedByName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        StatusBadge(
          text: context.tr('medications.extra_dose_badge'),
          tone: StatusTone.info,
        ),
        if ((circleId, name) case (final String circle, final String who))
          RecorderLine(
            name: who,
            photoPath: personPhotoPath(circle, dose.recordedByAccountId),
            avatarCode: dose.recordedByAvatarCode,
            large: true,
          ),
      ],
    );
  }
}
