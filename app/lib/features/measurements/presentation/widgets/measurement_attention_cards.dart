import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_actions.dart';
import 'package:app/features/measurements/presentation/widgets/reading_follow_up_button.dart';
import 'package:app/features/measurements/presentation/widgets/reading_status_pill.dart';
import 'package:app/features/measurements/presentation/widgets/reading_titles.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The cards of the attention box, drawn as readings are in «السجل»:
/// «سجّل» and «تخطي» for a missed task (only «تخطي» once the next task of
/// its kind is due at [now], a wall time), «تابعتها» for a reading outside
/// its normal range, with its value, level and range.
List<Widget> measurementAttentionCards(
  BuildContext context,
  List<MeasurementOccurrence> missed,
  List<MeasurementReading> outside, {
  required DateTime now,
  String? circleId,
}) => <Widget>[
  for (final MeasurementOccurrence task in missed)
    _focused(
      circleId,
      task,
      MeasurementAttentionCard(
        kind: task.kind,
        title: _TaskTitle(task: task),
        status: StatusBadge(
          text: context.tr('measurements.unrecorded'),
          tone: StatusTone.attention,
        ),
        // Once the next task of its kind is due a reading would answer that
        // one: only «تخطي» stays, and this line says why.
        lines: <Widget>[
          Text(
            context.tr(
              task.supersededAt(now)
                  ? 'measurements.superseded'
                  : 'measurements.not_recorded',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        actions: <Widget>[
          MeasurementTaskActions(
            task: task,
            superseded: task.supersededAt(now),
            sayWhy: false,
          ),
        ],
      ),
    ),
  for (final MeasurementReading reading in outside)
    MeasurementAttentionCard(
      kind: reading.kind,
      title: ReadingTitles(reading: reading),
      status: ReadingValue(reading: reading),
      lines: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ReadingStatusPill(reading: reading),
        ),
        if (reading.range != null)
          Text(
            readingRangeText(context, reading),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
      actions: <Widget>[ReadingFollowUpButton(reading: reading)],
    ),
];

/// [card], tinted when a tapped notification is about [task].
Widget _focused(String? circleId, MeasurementOccurrence task, Widget card) =>
    circleId == null
    ? card
    : FocusMark(
        itemKey: measurementSnoozeKey(circleId, task),
        radius: AppRadius.m,
        inset: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: card,
      );

/// A missed task's kind and time, and its day under them, as a reading's
/// titles are.
class _TaskTitle extends StatelessWidget {
  const _TaskTitle({required this.task});

  final MeasurementOccurrence task;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${measurementKindTitle(context, task.kind)} · '
            '${clockText(task.time)}',
            style: text.titleMedium,
            semanticsLabel: spoken(
              '${measurementKindTitle(context, task.kind)}، '
              '${clockText(task.time)}',
            ),
          ),
          Text(
            formatMedicationDate(context, task.scheduledOn),
            style: text.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
