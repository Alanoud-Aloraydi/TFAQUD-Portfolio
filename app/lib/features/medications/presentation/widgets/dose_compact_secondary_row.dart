import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The second line of the compact dose controls: «وقت ثاني» today, and
/// «تخطي» on any day.
List<Widget> doseCompactSecondaryRow(
  BuildContext context, {
  required DoseOccurrence occurrence,
  required ButtonStyle compactText,
  required bool isToday,
  String? circleId,
}) => <Widget>[
  if (isToday)
    Expanded(
      child: TextButton.icon(
        style: compactText,
        onPressed: () =>
            takeDoseAtDifferentTime(context, occurrence, circleId: circleId),
        icon: const Icon(CupertinoIcons.clock, size: 16),
        label: Text(
          CareVoice.tr(context, circleId, 'medications.different_time_short'),
        ),
      ),
    )
  else
    const Spacer(),
  const SizedBox(width: AppSpacing.sm),
  Expanded(
    child: TextButton.icon(
      style: compactText,
      onPressed: () => skipDose(context, occurrence, circleId: circleId),
      icon: const Icon(CupertinoIcons.minus_circle, size: 16),
      label: Text(context.tr('medications.skip_short')),
    ),
  ),
];
