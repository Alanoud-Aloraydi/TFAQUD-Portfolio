import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_actions.dart';
import 'package:app/features/medications/presentation/widgets/dose_snooze_button.dart';
import 'package:app/features/medications/presentation/widgets/dose_taken_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The first line of the compact dose controls: «أُخذت» and
/// «ذكّرني لاحقًا» today, and «وقت ثاني» on an earlier day.
List<Widget> doseCompactPrimaryRow(
  BuildContext context, {
  required DoseOccurrence occurrence,
  required ButtonStyle compact,
  required bool isToday,
  required bool canSnooze,
  String? circleId,
}) => <Widget>[
  if (isToday)
    Expanded(
      child: doseTakenButton(
        context,
        occurrence: occurrence,
        style: compact,
        circleId: circleId,
      ),
    ),
  if (isToday && canSnooze) const SizedBox(width: AppSpacing.sm),
  if (canSnooze)
    Expanded(
      child: DoseSnoozeButton(
        occurrence: occurrence,
        circleId: circleId!,
        style: compact,
      ),
    ),
  if (!isToday)
    Expanded(
      child: FilledButton.tonalIcon(
        style: compact,
        onPressed: () =>
            takeDoseAtDifferentTime(context, occurrence, circleId: circleId),
        icon: const Icon(CupertinoIcons.clock, size: 16),
        label: Text(
          CareVoice.tr(context, circleId, 'medications.different_time_short'),
        ),
      ),
    ),
];
