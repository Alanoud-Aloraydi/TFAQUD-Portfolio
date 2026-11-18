import 'package:app/features/measurements/domain/measurement_conditions.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_scope.dart';

/// What the reading sheet makes of what is typed and chosen.
mixin MeasurementReadingSheetValues on MeasurementReadingSheetScope {
  /// The meal state chosen among the conditions, which picks the glucose
  /// range.
  String? get mealState => conditions
      .where(
        (code) => const <String>[
          'fasting',
          'before_meal',
          'after_meal',
          'bedtime',
        ].contains(code),
      )
      .firstOrNull;

  /// Where the typed value falls in [range]; null until it is a number.
  MeasurementLevel? levelIn(NormalRange range) {
    final int? one = int.tryParse(
      kind == MeasurementKind.bp ? systolic.text : glucose.text,
    );
    if (one == null || one < 1) return null;
    if (kind == MeasurementKind.glucose) return range.levelOf(one);
    final int? two = int.tryParse(diastolic.text);
    return two == null || two < 1 ? null : range.levelOf(one, two);
  }

  /// Switches to [value], keeping only the conditions it offers.
  void changeKind(MeasurementKind value) => setState(() {
    kind = value;
    // Fasting is not for blood pressure.
    final offered = MeasurementConditions.offered(value);
    conditions = [
      for (final code in conditions)
        if (offered.contains(code)) code,
    ];
  });
}
