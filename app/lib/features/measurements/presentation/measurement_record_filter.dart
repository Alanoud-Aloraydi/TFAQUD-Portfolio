import 'package:app/features/measurements/domain/measurement_kind.dart';

/// Which readings «السجل» shows: every kind, or one of them.
enum MeasurementRecordFilter {
  all,
  glucose,
  bp;

  /// The kind this filter keeps; null for [all].
  MeasurementKind? get kind => switch (this) {
    all => null,
    glucose => MeasurementKind.glucose,
    bp => MeasurementKind.bp,
  };

  /// Whether a reading of [value] belongs in the list.
  bool keeps(MeasurementKind value) => kind == null || kind == value;

  /// The key of its words: «الكل», «سكر الدم», «ضغط الدم».
  String get labelKey => switch (this) {
    all => 'measurements.all',
    glucose => 'measurements.glucose',
    bp => 'measurements.bp',
  };
}
