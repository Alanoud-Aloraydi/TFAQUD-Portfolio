import 'package:app/core/widgets/overlays/skip_reason_sheet.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading_draft.dart';
import 'package:app/features/measurements/presentation/widgets/invalid_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Asks why the reading is skipped (optional) with the app's one skip
/// sheet, and returns the skipped reading to save; null when it is closed.
Future<MeasurementReadingDraft?> selectSkippedMeasurement(
  BuildContext context,
  MeasurementKind kind,
) async {
  final SkipReasonChoice? choice = await showSkipReasonSheet(
    context,
    title: context.tr('measurements.skip_title'),
    message: context.tr('measurements.skip_reason_optional'),
    reasons: <SkipReasonOption>[
      for (final MeasurementSkipReason reason in MeasurementSkipReason.values)
        SkipReasonOption(
          reason.apiValue,
          context.tr('measurements.skip_reason.${reason.name}'),
        ),
    ],
    noteLabel: context.tr('measurements.skip_reason_note'),
    confirmLabel: context.tr('measurements.skip_confirm'),
  );
  if (choice == null) return null;
  return MeasurementReadingDraft(
    kind: kind,
    outcome: 'skipped',
    skipReasonCode: choice.code,
    skipReasonNote: choice.note,
  );
}

String measurementSkipReasonText(
  BuildContext context,
  MeasurementReading reading,
) {
  final code = reading.skipReasonCode;
  if (code == null) return '';
  if (code == 'other' && reading.skipReasonNote?.isNotEmpty == true) {
    return reading.skipReasonNote!;
  }
  final key = switch (code) {
    'equipment_unavailable' => 'equipmentUnavailable',
    'patient_refused' => 'patientRefused',
    _ => code,
  };
  return context.tr('measurements.skip_reason.$key');
}

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
  String? get outOfRangeKey => isInvalidReadingKey(errorKey) ? errorKey : null;

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
