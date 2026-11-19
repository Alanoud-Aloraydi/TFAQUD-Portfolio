import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/data/datasources/medications_remote_data_source.dart';
import 'package:app/features/medications/data/repositories/repository_guard.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:multiple_result/multiple_result.dart';

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
