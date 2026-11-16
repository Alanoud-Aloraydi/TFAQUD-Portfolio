import 'package:app/features/medications/domain/entities/dose_unit.dart';

/// Adds dose unit value helpers to its target type.
extension DoseUnitValue on DoseUnit {
  String get apiValue => this == DoseUnit.milliliter ? 'mL' : name;
}
