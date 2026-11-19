import 'package:app/core/network/dio_client.dart';
import 'package:app/core/network/medication_endpoints.dart';
import 'package:app/core/utils/api_date.dart';
import 'package:app/features/medications/data/models/extra_dose_model.dart';
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
