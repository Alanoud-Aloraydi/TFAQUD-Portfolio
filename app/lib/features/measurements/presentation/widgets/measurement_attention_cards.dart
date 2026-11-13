import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The cards of the attention box: «سجّل» and «تخطي» for a missed task
/// (only «تخطي» once the next task of its kind is due at [now], a wall
/// time), «تابعتها» for a reading outside its normal range.
List<Widget> measurementAttentionCards(
  BuildContext context,
  List<MeasurementOccurrence> missed,
  List<MeasurementReading> outside, {
  required DateTime now,
}) => <Widget>[
  for (final MeasurementOccurrence task in missed)
    MeasurementAttentionCard(
      title:
          '${measurementKindTitle(context, task.kind)} · '
          '${clockText(task.time)}',
      // Once the next task of its kind is due a reading would answer that
      // one: only «تخطي» stays, and the subtitle says why.
      subtitle: context.tr(
        task.supersededAt(now)
            ? 'measurements.superseded'
            : 'measurements.not_recorded',
      ),
      dateText: formatMedicationDate(context, task.scheduledOn),
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
      title:
          '${measurementKindTitle(context, reading.kind)} '
          '${reading.valueText}',
      subtitle: reading.level == null
          ? context.tr('measurements.outside_target')
          : '${reading.level!.label(context, reading.kind)} · '
                '${context.tr('measurements.outside_target')}',
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
