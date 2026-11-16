import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_skip_reason_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The small lines under a recorded dose of the history, the words
/// «جدول اليوم» uses: how long after its time it was taken, and why a
/// skipped dose was not taken.
List<Widget> doseHistoryNotes(
  BuildContext context,
  DoseRecord record,
  DoseRowStatus status,
) {
  final TextStyle? small = Theme.of(context).textTheme.bodySmall;
  return <Widget>[
    if (status.lateBy case final String lateBy) Text(lateBy, style: small),
    if (record.outcome == DoseOutcome.skipped && record.skipReasonCode != null)
      Text(
        context.tr(
          'medications.skip_reason_line',
          args: <String>[doseSkipReasonText(context, record)],
        ),
        style: small,
      ),
  ];
}
