import 'package:app/core/errors/failure.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/network/medication_endpoints.dart';
import 'package:app/core/utils/api_date.dart';
import 'package:app/features/medications/data/datasources/medications_remote_data_source.dart';
import 'package:app/features/medications/data/datasources/repository_guard.dart';
import 'package:app/features/medications/data/models/dose_occurrence_model.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:multiple_result/multiple_result.dart';

/// The requests about the doses of a range of days, and the answer to one.
mixin MedicationDoseRequests {
  DioClient get client;

  Future<List<DoseOccurrenceModel>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async {
    final response = await client.get(
      MedicationEndpoints.medicationOccurrences(circleId),
      queryParameters: {
        'from': apiDate(from),
        'to': apiDate(to),
        'plan_id': ?planId,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final values = body['medication_occurrences'] as List<dynamic>;
    return values
        .map(
          (item) => DoseOccurrenceModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<DoseRecord> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  ) async {
    final response = await client.put(
      MedicationEndpoints.medicationDoseRecord(
        circleId,
        occurrence.scheduleId,
        apiDate(occurrence.scheduledOn),
      ),
      data: record.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    return DoseRecordModel.fromJson(
      body['medication_dose_record'] as Map<String, dynamic>,
    ).toEntity();
  }
}

/// The doses of a range of days, and the answer to one, as the domain asks
/// for them.
mixin MedicationDoseRepository on RepositoryGuard {
  BaseMedicationsRemoteDataSource get remote;

  Future<Result<List<DoseOccurrence>, Failure>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) => guard(() async {
    final models = await remote.getOccurrences(
      circleId,
      from,
      to,
      planId: planId,
    );
    return models.map((model) => model.toEntity()).toList();
  });

  Future<Result<DoseRecord, Failure>> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  ) => guard(() => remote.recordDose(circleId, occurrence, record));

  Future<Result<ExtraDose, Failure>> recordExtraDose(
    String circleId,
    ExtraDoseDraft draft,
  ) => guard(() => remote.recordExtraDose(circleId, draft));

  Future<Result<List<ExtraDose>, Failure>> getExtraDoses(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) => guard(() => remote.getExtraDoses(circleId, from, to, planId: planId));
}
