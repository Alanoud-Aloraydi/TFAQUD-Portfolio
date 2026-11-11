import 'package:app/features/measurements/domain/measurement.dart';

/// The target band a month chart draws: the one every reading of the month
/// was judged against, or, when the month has no readings, the one of the
/// active plan that already applies.
class ChartTarget {
  const ChartTarget(this.low, this.high);

  /// Glucose: the lowest value. Blood pressure: the diastolic limit.
  final int? low;

  /// Glucose: the highest value. Blood pressure: the systolic limit.
  final int? high;

  bool get isSet => low != null && high != null;

  factory ChartTarget.of({
    required MeasurementKind kind,
    required List<MeasurementReading> readings,
    required List<MeasurementPlan> plans,
    required DateTime month,
  }) {
    final MeasurementReading? first = readings.firstOrNull;
    final bool shared =
        first != null &&
        readings.every(
          (r) =>
              r.glucoseLow == first.glucoseLow &&
              r.glucoseHigh == first.glucoseHigh &&
              r.systolicLimit == first.systolicLimit &&
              r.diastolicLimit == first.diastolicLimit,
        );
    final MeasurementVersion? version = plans
        .where((plan) => plan.kind == kind && plan.stoppedAt == null)
        .firstOrNull
        ?.version;
    final DateTime monthEnd = DateTime(month.year, month.month + 1, 0);
    final bool planApplies =
        readings.isEmpty &&
        version != null &&
        !version.effectiveFromOn.isAfter(monthEnd);
    final MeasurementReading? fromReading = shared ? first : null;
    final MeasurementVersion? fromPlan = planApplies ? version : null;
    return kind == MeasurementKind.glucose
        ? ChartTarget(
            fromReading?.glucoseLow ?? fromPlan?.glucoseLow,
            fromReading?.glucoseHigh ?? fromPlan?.glucoseHigh,
          )
        : ChartTarget(
            fromReading?.diastolicLimit ?? fromPlan?.diastolicLimit,
            fromReading?.systolicLimit ?? fromPlan?.systolicLimit,
          );
  }
}
