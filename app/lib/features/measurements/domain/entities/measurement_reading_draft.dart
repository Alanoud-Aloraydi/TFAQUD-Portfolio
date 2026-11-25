import 'package:app/features/measurements/domain/entities/measurement_conditions.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';

/// Holds editable measurement reading values before saving.
class MeasurementReadingDraft {
  const MeasurementReadingDraft({
    required this.kind,
    required this.outcome,
    this.measuredAt,
    this.valueOne,
    this.valueTwo,
    this.conditions = const <String>[],
    this.otherCondition,
    this.note,
    this.skipReasonCode,
    this.skipReasonNote,
  });

  final MeasurementKind kind;
  final String outcome;
  final DateTime? measuredAt;
  final int? valueOne;
  final int? valueTwo;

  /// «ظروف القياس» ([MeasurementConditions]), none or more.
  final List<String> conditions;

  /// What «أخرى» was, in the reader's words; sent only with «أخرى».
  final String? otherCondition;
  final String? note;
  final String? skipReasonCode;
  final String? skipReasonNote;

  Map<String, dynamic> toJson() => {
    'kind': kind.wire,
    'outcome': outcome,
    'measured_at': measuredAt?.toUtc().toIso8601String(),
    if (kind == MeasurementKind.glucose)
      'glucose_value': valueOne
    else ...{
      'systolic_value': valueOne,
      'diastolic_value': valueTwo,
    },
    'conditions': conditions,
    if (otherCondition != null && conditions.contains('other'))
      'other_text': otherCondition,
    'note': note,
    'skip_reason_code': skipReasonCode,
    'skip_reason_note': skipReasonNote,
  };
}
