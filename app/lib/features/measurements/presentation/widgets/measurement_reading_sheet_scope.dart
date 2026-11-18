import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:flutter/material.dart';

/// What the reading sheet holds while it is open: the kind, the conditions,
/// the time, what is typed, and the save and error flags.
mixin MeasurementReadingSheetScope on State<MeasurementReadingSheet> {
  late MeasurementKind kind = widget.occurrence?.kind ?? MeasurementKind.bp;

  /// The planned glucose state is only a starting point; these remain the
  /// actual conditions of the reading and can be changed by the recorder.
  late List<String> conditions = widget.occurrence?.measurementState == null
      ? const <String>[]
      : <String>[widget.occurrence!.measurementState!];

  /// The time picked; until then, now on the patient's clock.
  TimeOfDay? picked;
  TimeOfDay get time =>
      picked ?? TimeOfDay.fromDateTime(PatientClockScope.of(context).now());
  final systolic = TextEditingController();
  final diastolic = TextEditingController();
  final glucose = TextEditingController();
  final note = TextEditingController();

  /// What «أخرى» was, in the reader's words.
  final otherCondition = TextEditingController();

  /// The longest words «أخرى» takes, as the server keeps them.
  static const int otherConditionLength = 60;
  bool saving = false;
  String? errorKey;

  /// The numbers out of range: said under them, not above the button.
  String? get outOfRangeKey =>
      errorKey == 'measurements.invalid_reading' ? errorKey : null;

  @override
  void dispose() {
    systolic.dispose();
    diastolic.dispose();
    glucose.dispose();
    note.dispose();
    otherCondition.dispose();
    super.dispose();
  }
}
