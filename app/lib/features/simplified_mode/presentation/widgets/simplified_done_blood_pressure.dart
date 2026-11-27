part of 'simplified_done_message.dart';

class SimplifiedDoneBloodPressure extends SimplifiedDoneMessage {
  const SimplifiedDoneBloodPressure(this.upper, this.lower, {this.level});

  final int upper;
  final int lower;
  final MeasurementLevel? level;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_bp', args: <String>['$upper', '$lower']);

  @override
  MeasurementVerdict? get verdict => switch (level) {
    final MeasurementLevel level => (kind: MeasurementKind.bp, level: level),
    null => null,
  };
}
