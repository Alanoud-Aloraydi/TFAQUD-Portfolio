import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement.dart';

/// The measurements of «يحتاج انتباهك»: tasks nobody recorded, and today's
/// readings outside their target that nobody followed up yet.
abstract final class MeasurementAttention {
  /// The tasks nobody recorded.
  static List<MeasurementOccurrence> missed(
    List<MeasurementOccurrence> tasks,
  ) => tasks.where((item) => item.status == MeasurementStatus.missed).toList();

  /// The readings of the patient's today outside their target and not yet
  /// followed up.
  static List<MeasurementReading> outside(
    List<MeasurementReading> readings,
    PatientClock clock,
  ) => readings
      .where(
        (item) =>
            item.outsideTarget == true &&
            item.followedUpAt == null &&
            item.measuredAt != null &&
            clock.today(item.measuredAt!) == clock.today(),
      )
      .toList();

  /// How many cards the attention box shows for [clock]'s patient.
  static int count(
    List<MeasurementOccurrence> tasks,
    List<MeasurementReading> readings,
    PatientClock clock,
  ) => missed(tasks).length + outside(readings, clock).length;
}
