import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The kind of a reading and when it was taken, on the patient's clock. A
/// skipped reading has only the day it was planned for.
class ReadingTitles extends StatelessWidget {
  const ReadingTitles({super.key, required this.reading});

  final MeasurementReading reading;

  String _when(BuildContext context) {
    if (reading.outcome == 'skipped') {
      return formatBirthDate(context, reading.scheduledOn!);
    }
    final PatientClock clock = PatientClockScope.of(context);
    final DateTime at = clock.wallTime(reading.measuredAt!);
    return '${formatBirthDate(context, at)}، ${wallTimeText(at)}';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool glucose = reading.kind == MeasurementKind.glucose;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr(glucose ? 'measurements.glucose' : 'measurements.bp'),
            style: text.titleMedium,
          ),
          Text(
            _when(context),
            style: text.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// «وقت القياس الفعلي» of the reading sheet: the [time] shown, and the
/// time sheet to pick another.
class ReadingTimeGroup extends StatelessWidget {
  const ReadingTimeGroup({
    super.key,
    required this.time,
    required this.onPicked,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onPicked;

  @override
  Widget build(BuildContext context) => InsetGroup(
    children: [
      InsetRow(
        label: context.tr('measurements.actual_time'),
        value: timeOfDayText(time),
        onTap: () async {
          final selected = await showTafaqodTimeSheet(
            context,
            title: context.tr('measurements.actual_time'),
            initialTime: time,
          );
          if (selected != null && context.mounted) onPicked(selected);
        },
      ),
    ],
  );
}
