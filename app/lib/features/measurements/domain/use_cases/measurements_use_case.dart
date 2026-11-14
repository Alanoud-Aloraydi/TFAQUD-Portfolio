import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository_domain.dart';

/// The measurement reads and writes the application is allowed to make.
///
/// The only way into the feature from outside its data layer: the cubits,
/// the reminders, and the calendar take this, never the repository, so the
/// presentation never depends on how a measurement is stored.
class MeasurementsUseCase {
  MeasurementsUseCase(this._repository);

  final MeasurementsRepositoryDomain _repository;

  /// The circle whose plans changed, so the lists showing them read again.
  Stream<String> get changes => _repository.changes;

  /// The circle where a reading was saved or a task answered, so its
  /// reminder is taken off and the lists showing it read again.
  Stream<String> get recorded => _repository.recorded;

  Future<List<MeasurementPlan>> plans(String circleId) =>
      _repository.plans(circleId);

  Future<MeasurementPlan> createPlan(
    String circleId,
    MeasurementPlanDraft draft,
  ) => _repository.createPlan(circleId, draft);

  Future<MeasurementPlan> revisePlan(
    String circleId,
    MeasurementPlan plan,
    MeasurementPlanDraft draft,
  ) => _repository.revisePlan(circleId, plan, draft);

  Future<MeasurementPlan> stopPlan(String circleId, String planId) =>
      _repository.stopPlan(circleId, planId);

  Future<List<MeasurementOccurrence>> occurrences(
    String circleId,
    DateTime from,
    DateTime to,
  ) => _repository.occurrences(circleId, from, to);

  Future<List<MeasurementReading>> readings(
    String circleId,
    DateTime from,
    DateTime to,
  ) => _repository.readings(circleId, from, to);

  Future<List<MeasurementReading>> allReadings(String circleId) =>
      _repository.allReadings(circleId);

  Future<MeasurementReading> record(
    String circleId,
    MeasurementReadingDraft draft, {
    MeasurementOccurrence? occurrence,
  }) => _repository.record(circleId, draft, occurrence: occurrence);

  Future<MeasurementReading> followUp(String circleId, String readingId) =>
      _repository.followUp(circleId, readingId);
}
