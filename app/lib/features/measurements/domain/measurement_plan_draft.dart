import 'package:app/core/utils/api_date.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_version.dart';

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
