import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';

/// [tasks] in the same order, each knowing when the next task of its kind
/// in the list is ([MeasurementOccurrence.nextAt]).
List<MeasurementOccurrence> linkNextTasks(List<MeasurementOccurrence> tasks) {
  DateTime at(MeasurementOccurrence task) =>
      wallClockAt(task.scheduledOn, task.time);
  return <MeasurementOccurrence>[
    for (final MeasurementOccurrence task in tasks)
      task.withNextAt(
        tasks
            .where(
              (other) => other.kind == task.kind && at(other).isAfter(at(task)),
            )
            .map(at)
            .fold<DateTime?>(
              null,
              (DateTime? first, DateTime moment) =>
                  first == null || moment.isBefore(first) ? moment : first,
            ),
      ),
  ];
}
