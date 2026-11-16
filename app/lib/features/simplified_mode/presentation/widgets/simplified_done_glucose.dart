part of 'simplified_done_message.dart';

class SimplifiedDoneGlucose extends SimplifiedDoneMessage {
  const SimplifiedDoneGlucose(this.value, {this.level});

  final int value;
  final MeasurementLevel? level;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_glucose', args: <String>['$value']);

  @override
  MeasurementVerdict? verdict(BuildContext context) => level == null
      ? null
      : MeasurementVerdict(
          level!.label(context, MeasurementKind.glucose),
          level!,
        );
}
