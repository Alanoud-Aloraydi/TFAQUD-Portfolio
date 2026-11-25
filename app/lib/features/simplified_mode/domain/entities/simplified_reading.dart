import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan_draft.dart';
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

  /// Whether the server would take the numbers ([MeasurementLimits]). The
  /// conditions are kept valid as they are chosen
  /// (MeasurementConditions.toggle).
  bool get isValid => MeasurementLimits.reading(kind, valueOne, valueTwo);

  @override
  List<Object?> get props => [kind, valueOne, valueTwo, conditions, note];
}

/// The simplified mode's text size, chosen in «حسابي»: «صغير»,
/// «متوسط», «كبير». Its [factor] scales every text of the mode, on top
/// of the phone's own text size.
enum SimplifiedTextSize {
  normal(1),
  large(1.15),
  larger(1.3);

  const SimplifiedTextSize(this.factor);

  final double factor;
}
