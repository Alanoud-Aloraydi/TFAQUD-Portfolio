import 'package:app/features/medications/domain/entities/dose_unit.dart';
import 'package:app/features/medications/domain/entities/dose_unit_value.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';

/// One extra dose of the API: `{id, plan_id, taken_at, dose_value,
/// dose_unit, recorded_at, recorded_by}`.
ExtraDose extraDoseFromJson(Map<String, dynamic> json) {
  final recordedBy = json['recorded_by'] as Map<String, dynamic>?;
  final String unit = json['dose_unit'] as String;
  return ExtraDose(
    id: json['id'] as String,
    planId: json['plan_id'] as String,
    takenAt: DateTime.parse(json['taken_at'] as String).toLocal(),
    doseValue: double.parse(json['dose_value'] as String),
    doseUnit: unit == 'mL' ? DoseUnit.milliliter : DoseUnit.values.byName(unit),
    recordedByAccountId: recordedBy?['account_id'] as String?,
    recordedByName: recordedBy?['name'] as String?,
    recordedByAvatarCode: recordedBy?['avatar_code'] as String?,
  );
}

/// The body of `POST medication-extra-doses`: the time in UTC, the dose as
/// a number, as a dose time sends it.
Map<String, Object?> extraDoseDraftToJson(ExtraDoseDraft draft) => {
  'plan_id': draft.planId,
  'taken_at': draft.takenAt.toUtc().toIso8601String(),
  'dose_value': draft.doseValue,
  'dose_unit': draft.doseUnit.apiValue,
};
