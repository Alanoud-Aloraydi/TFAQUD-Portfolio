import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/reading_status_pill.dart';
import 'package:app/features/measurements/presentation/widgets/reading_titles.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The cards of the attention box, drawn as readings are in «السجل»:
/// «سجّل» and «تخطي» for a missed task (only «تخطي» once the next task of
/// its kind is due at [now], a wall time), «تابعتها» for a reading outside
/// its normal range, with its value, level and range.
List<Widget> measurementAttentionCards(
  BuildContext context,
  List<MeasurementOccurrence> missed,
  List<MeasurementReading> outside, {
  required DateTime now,
}) => <Widget>[
  for (final MeasurementOccurrence task in missed)
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
        if (!task.supersededAt(now))
          FilledButton(
            onPressed: () =>
                showMeasurementReadingSheet(context, occurrence: task),
            child: Text(context.tr('measurements.record_reading')),
          ),
        TextButton(
          onPressed: () => skipMeasurement(context, task),
          child: Text(context.tr('measurements.skip')),
        ),
      ],
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
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            final String? messageKey = await context
                .read<MeasurementReadingsCubit>()
                .followUp(reading);
            if (!context.mounted) return;
            if (messageKey == null) {
              AppToast.show(context, 'toast.follow_up_done');
            } else {
              showMeasurementMessage(context, messageKey);
            }
          },
          child: Text(context.tr('measurements.follow_up')),
        ),
      ],
    ),
];

/// A missed task's kind and time, and its day under them, as a reading's
/// titles are.
class _TaskTitle extends StatelessWidget {
  const _TaskTitle({required this.task});

  final MeasurementOccurrence task;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${measurementKindTitle(context, task.kind)} · '
          '${clockText(task.time)}',
          style: text.titleMedium,
        ),
        Text(
          formatMedicationDate(context, task.scheduledOn),
          style: text.bodySmall?.copyWith(color: context.tokens.textSecondary),
        ),
      ],
    );
  }
}
