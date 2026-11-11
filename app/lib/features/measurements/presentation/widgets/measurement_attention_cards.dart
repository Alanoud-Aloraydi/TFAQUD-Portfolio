import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The cards of the attention box: «سجّل» and «تخطي» for a missed task,
/// «تابعتها» for a reading outside its target.
List<Widget> measurementAttentionCards(
  BuildContext context,
  List<MeasurementOccurrence> missed,
  List<MeasurementReading> outside,
) => <Widget>[
  for (final MeasurementOccurrence task in missed)
    MeasurementAttentionCard(
      title:
          '${measurementKindTitle(context, task.kind)} · '
          '${clockText(task.time)}',
      subtitle: context.tr('measurements.not_recorded'),
      dateText: formatMedicationDate(context, task.scheduledOn),
      actions: <Widget>[
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
      subtitle: context.tr('measurements.outside_target'),
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
