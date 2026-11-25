import 'package:app/core/utils/api_date.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/domain/entities/measurement_version.dart';

/// Holds editable measurement plan values before saving.
class MeasurementPlanDraft {
  const MeasurementPlanDraft({
    required this.kind,
    required this.times,
    required this.weekdays,
    required this.startsOn,
    required this.missedAfterMinutes,
  });

  final MeasurementKind kind;

  /// The reading times of a day, one or more.
  final List<MeasurementTime> times;
  final List<int> weekdays;
  final DateTime startsOn;
  final int missedAfterMinutes;

  /// One reading time is sent as before (`time_of_day`), so it saves on a
  /// server without several times too; more are sent as `times`, and so is
  /// one with conditions only a list holds. With [expectedVersion] (a
  /// revision: the number of the plan's latest version) [startsOn] is the
  /// day the change takes effect.
  Map<String, dynamic> toJson({int? expectedVersion}) => {
    'kind': kind.wire,
    'times': [for (final MeasurementTime item in times) item.toJson()],
    'weekdays': weekdays,
    'starts_on': apiDate(startsOn),
    'effective_from_on': ?(expectedVersion == null ? null : apiDate(startsOn)),
    'missed_after_minutes': missedAfterMinutes,
    'expected_version_number': ?expectedVersion,
  };
}

/// Where a plan began.
extension MeasurementPlanStart on MeasurementPlan {
  /// The first day of the plan: its earliest version's (an edit starts a
  /// later version).
  DateTime get startsOn => <MeasurementVersion>[version, ...history]
      .map((MeasurementVersion item) => item.effectiveFromOn)
      .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);
}

/// The condition a plan names for itself.
extension MeasurementPlanCondition on MeasurementPlan {
  /// The «حالة القياس» of the plan's only reading time; none when it has
  /// several, each of which has its own.
  String? get singleCondition => version.readingTimes.length == 1
      ? version.readingTimes.single.measurementState
      : null;
}

/// What a reading may be. The old rule was 1 to 999 for every number, so a
/// diastolic typed as 18 instead of 80 was saved, drawn as a bar across the
/// whole chart and carried into the health summary a doctor reads. These
/// bounds are wide enough for a reading worth calling an ambulance over and
/// narrow enough to catch a slip of the finger. The backend holds the same
/// numbers in app/measurements/inputs.py; change them together.
abstract final class MeasurementLimits {
  /// The upper number of a blood pressure.
  static const int systolicLow = 60;
  static const int systolicHigh = 260;

  /// The lower number of a blood pressure.
  static const int diastolicLow = 30;
  static const int diastolicHigh = 160;

  static const int glucoseLow = 20;
  static const int glucoseHigh = 600;

  static bool glucose(int value) => value >= glucoseLow && value <= glucoseHigh;

  /// A blood pressure needs both numbers, and the upper one above the
  /// lower one.
  static bool pressure(int systolic, int diastolic) =>
      systolic >= systolicLow &&
      systolic <= systolicHigh &&
      diastolic >= diastolicLow &&
      diastolic <= diastolicHigh &&
      systolic > diastolic;

  /// Whether [one], and [two] for a blood pressure, may be saved.
  static bool reading(MeasurementKind kind, int one, int? two) =>
      kind == MeasurementKind.glucose
      ? two == null && glucose(one)
      : two != null && pressure(one, two);
}
