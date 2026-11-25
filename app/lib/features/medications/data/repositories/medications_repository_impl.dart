import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/data/datasources/medication_dose_requests.dart';
import 'package:app/features/medications/data/datasources/medications_remote_data_source.dart';
import 'package:app/features/medications/data/datasources/repository_guard.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository.dart';
import 'package:multiple_result/multiple_result.dart';

/// The server owns the medicines and the dose records.
class MedicationsRepositoryImpl
    with RepositoryGuard, MedicationDoseRepository
    implements MedicationsRepository {
  MedicationsRepositoryImpl(this.remote);

  @override
  final BaseMedicationsRemoteDataSource remote;

  @override
  Future<Result<List<MedicationPlan>, Failure>> getPlans(String circleId) =>
      guard(() async {
        final models = await remote.getPlans(circleId);
        return models.map((model) => model.toEntity()).toList();
      });

  @override
  Future<Result<MedicationPlan, Failure>> getPlan(
    String circleId,
    String planId,
  ) => guard(() async {
    final model = await remote.getPlan(circleId, planId);
    return model.toEntity();
  });

  @override
  Future<Result<MedicationPlan, Failure>> createPlan(
    String circleId,
    MedicationPlanDraft draft,
  ) => guard(() async {
    final model = await remote.createPlan(circleId, draft);
    return model.toEntity();
  });

  @override
  Future<Result<MedicationPlan, Failure>> revisePlan(
    String circleId,
    String planId,
    int expectedVersion,
    MedicationPlanDraft draft,
  ) => guard(() async {
    final model = await remote.revisePlan(
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
  ) => guard(() async {
    final model = await remote.discontinuePlan(circleId, planId);
    return model.toEntity();
  });

  @override
  Future<Result<MedicationPlan, Failure>> cancelPendingPlan(
    String circleId,
    String planId,
    int expectedVersion,
  ) => guard(() async {
    final model = await remote.cancelPendingPlan(
      circleId,
      planId,
      expectedVersion,
    );
    return model.toEntity();
  });
}
