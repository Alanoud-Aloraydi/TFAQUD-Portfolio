import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/layout/filtered_history.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_readings_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «سجل القياسات» under the charts: the month's [readings] gathered in a
/// box that folds away, as «سجل الجرعات» is, filtered by the kind
/// («الكل»، «سكر الدم»، «ضغط الدم»), the month and who recorded.
class MeasurementReadingsHistory extends StatelessWidget {
  const MeasurementReadingsHistory({
    super.key,
    required this.circleId,
    required this.readings,
  });

  final String circleId;
  final List<MeasurementReading> readings;

  @override
  Widget build(BuildContext context) {
    final clock = PatientClockScope.of(context);
    return FilteredHistory<MeasurementReading>(
      title: context.tr('measurements.readings'),
      items: readings,
      // The day it was measured where the patient lives.
      dayOf: (r) => clock.wallTime(r.measuredAt ?? r.recordedAt),
      byOf: (r) => (r.recordedByAccountId, r.recordedByName),
      kinds: <String, String>{
        for (final MeasurementKind kind in MeasurementKind.values)
          kind.name: context.tr('measurements.${kind.name}'),
      },
      kindOf: (r) => r.kind.name,
      empty: EmptyStateNote(context.tr('measurements.no_readings')),
      builder: (shown) =>
          MeasurementReadingsList(circleId: circleId, readings: shown),
    );
  }
}
