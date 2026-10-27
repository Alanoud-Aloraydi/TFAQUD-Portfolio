import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/medications/data/datasources/medications_remote_data_source.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@LazySingleton(as: MedicationsRepositoryDomain)
class MedicationsRepositoryData implements MedicationsRepositoryDomain {
  MedicationsRepositoryData(this._remote);

  final BaseMedicationsRemoteDataSource _remote;

  @override
  Future<Result<List<MedicationPlan>, Failure>> getPlans(String circleId) =>
      _guard(() async {
        final models = await _remote.getPlans(circleId);
        return models.map((model) => model.toEntity()).toList();
      });

  @override
  Future<Result<MedicationPlan, Failure>> getPlan(
    String circleId,
    String planId,
  ) => _guard(() async {
    final model = await _remote.getPlan(circleId, planId);
    return model.toEntity();
  });

  @override
  Future<Result<MedicationPlan, Failure>> createPlan(
    String circleId,
    MedicationPlanDraft draft,
  ) => _guard(() async {
    final model = await _remote.createPlan(circleId, draft);
    return model.toEntity();
  });

  @override
  Future<Result<MedicationPlan, Failure>> revisePlan(
    String circleId,
    String planId,
    int expectedVersion,
    MedicationPlanDraft draft,
  ) => _guard(() async {
    final model = await _remote.revisePlan(
      circleId,
      planId,
      expectedVersion,
      draft,
    );
    return model.toEntity();
  });

  @override
  Future<Result<MedicationPlan, Failure>> discontinuePlan(
    String circleId,
    String planId,
  ) => _guard(() async {
    final model = await _remote.discontinuePlan(circleId, planId);
    return model.toEntity();
  });

  @override
  Future<Result<List<DoseOccurrence>, Failure>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) => _guard(() async {
    final models = await _remote.getOccurrences(
      circleId,
      from,
      to,
      planId: planId,
    );
    return models.map((model) => model.toEntity()).toList();
  });

  @override
  Future<Result<DoseRecord, Failure>> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  ) => _guard(() => _remote.recordDose(circleId, occurrence, record));

  Future<Result<T, Failure>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Success(await operation());
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
