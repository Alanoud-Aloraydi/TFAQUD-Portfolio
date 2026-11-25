import 'package:app/core/network/dio_client.dart';
import 'package:app/core/network/medication_endpoints.dart';
import 'package:app/core/utils/api_date.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';

/// The requests of «سجّل جرعة الآن»: recording an extra dose, and those of
/// a range of days.
mixin MedicationExtraDoseRequests {
  DioClient get client;

  Future<ExtraDose> recordExtraDose(
    String circleId,
    ExtraDoseDraft draft,
  ) async {
    final response = await client.post(
      MedicationEndpoints.medicationExtraDoses(circleId),
      data: extraDoseDraftToJson(draft),
    );
    final body = response.data as Map<String, dynamic>;
    return extraDoseFromJson(
      body['medication_extra_dose'] as Map<String, dynamic>,
    );
  }

  Future<List<ExtraDose>> getExtraDoses(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async {
    final response = await client.get(
      MedicationEndpoints.medicationExtraDoses(circleId),
      queryParameters: {
        'from': apiDate(from),
        'to': apiDate(to),
        'plan_id': ?planId,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return (body['medication_extra_doses'] as List<dynamic>)
        .map((item) => extraDoseFromJson(item as Map<String, dynamic>))
        .toList();
  }
}

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
