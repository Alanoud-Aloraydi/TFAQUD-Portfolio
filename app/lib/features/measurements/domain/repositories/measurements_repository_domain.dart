import 'package:app/features/measurements/domain/measurement.dart';

/// The measurement plans, readings, and tasks of a circle, wherever they
/// are kept.
abstract class MeasurementsRepositoryDomain {
  /// The circle whose plans changed, each time a change is accepted.
  Stream<String> get changes;

  /// The circle where a reading was saved or a task answered, here or
  /// elsewhere. Apart from [changes]: a reading does not change a plan.
  Stream<String> get recorded;

  /// Every plan, stopped ones too.
  Future<List<MeasurementPlan>> plans(String circleId);

  Future<MeasurementPlan> createPlan(
    String circleId,
    MeasurementPlanDraft draft,
  );

  /// Changes [plan] from [draft]'s start on; readings already taken keep
  /// the version they were taken under.
  Future<MeasurementPlan> revisePlan(
    String circleId,
    MeasurementPlan plan,
    MeasurementPlanDraft draft,
  );

  /// Stops [planId]: no task after now.
  Future<MeasurementPlan> stopPlan(String circleId, String planId);

  /// The tasks of the patient's days [from] to [to], both included.
  Future<List<MeasurementOccurrence>> occurrences(
    String circleId,
    DateTime from,
    DateTime to,
  );

  /// The readings of the patient's days [from] to [to], both included.
  Future<List<MeasurementReading>> readings(
    String circleId,
    DateTime from,
    DateTime to,
  );

  /// Every reading, for the record export.
  Future<List<MeasurementReading>> allReadings(String circleId);

  /// Saves [draft]: the answer to [occurrence], or a free reading without
  /// it.
  Future<MeasurementReading> record(
    String circleId,
    MeasurementReadingDraft draft, {
    MeasurementOccurrence? occurrence,
  });

  /// Marks [readingId], a reading outside its target, as followed up.
  Future<MeasurementReading> followUp(String circleId, String readingId);
}
