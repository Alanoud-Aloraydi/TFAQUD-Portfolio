import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The answers to one unrecorded dose where there is room for them: a
/// full-width button a line.
Widget doseRegularControls(
  BuildContext context, {
  required DoseOccurrence occurrence,
  required bool isToday,
  String? circleId,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (isToday) ...[
        FilledButton.icon(
          onPressed: () =>
              takeDoseNow(context, occurrence, circleId: circleId),
          icon: const Icon(CupertinoIcons.checkmark),
          label: Text(
            CareVoice.tr(context, circleId, 'medications.taken_now_action'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      OutlinedButton(
        onPressed: () =>
            takeDoseAtDifferentTime(context, occurrence, circleId: circleId),
        child: Text(context.tr('medications.different_time_action')),
      ),
      TextButton(
        onPressed: () => skipDose(context, occurrence, circleId: circleId),
        child: Text(context.tr('medications.skip_action')),
      ),
    ],
  );
}
