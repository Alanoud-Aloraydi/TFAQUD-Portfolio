import 'package:app/features/measurements/domain/measurement.dart';
import 'package:equatable/equatable.dart';

/// A reading the patient typed on «تسجيل قياس».
class SimplifiedReading extends Equatable {
  const SimplifiedReading({
    required this.kind,
    required this.valueOne,
    this.valueTwo,
    this.conditions = const <String>[],
    this.note,
  });

  final MeasurementKind kind;

  /// Glucose, or the upper (systolic) blood pressure.
  final int valueOne;

  /// The lower (diastolic) blood pressure; null for glucose.
  final int? valueTwo;

  /// «ظروف القياس» (MeasurementConditions codes), none or more; a task's
  /// start as its plan gives them.
  final List<String> conditions;

  /// What «أخرى» means, when it is chosen.
  final String? note;

  /// Whether the server would take the numbers: 1 to 999, and for blood
  /// pressure an upper number above the lower one. The conditions are kept
  /// valid as they are chosen (MeasurementConditions.toggle).
  bool get isValid {
    bool inRange(int value) => value >= 1 && value <= 999;
    if (!inRange(valueOne)) return false;
    if (kind == MeasurementKind.glucose) return valueTwo == null;
    final int? lower = valueTwo;
    return lower != null && inRange(lower) && valueOne > lower;
  }

  @override
  List<Object?> get props => [kind, valueOne, valueTwo, conditions, note];
}
