/// The measurement plans of one circle, their ranges, tasks and readings.
abstract final class MeasurementEndpoints {
  static String measurementPlans(String circleId) =>
      '/circles/$circleId/measurement-plans';
  static String measurementRanges(String circleId) =>
      '/circles/$circleId/measurement-ranges';
  static String measurementPlan(String circleId, String planId) =>
      '${measurementPlans(circleId)}/$planId';
  static String stopMeasurementPlan(String circleId, String planId) =>
      '${measurementPlan(circleId, planId)}/stop';
  static String measurementOccurrences(String circleId) =>
      '/circles/$circleId/measurement-occurrences';
  static String measurementReadings(String circleId) =>
      '/circles/$circleId/measurement-readings';
  static String measurementReadingsExport(String circleId) =>
      '${measurementReadings(circleId)}/export';

  /// One task: a version's reading [time] («HH:mm») on [scheduledOn].
  static String measurementRecord(
    String circleId,
    String versionId,
    String scheduledOn, {
    String? time,
  }) =>
      '/circles/$circleId/measurement-readings/$versionId/$scheduledOn'
      '${time == null ? '' : '?${Uri(queryParameters: <String, String>{'time': time}).query}'}';
  static String measurementFollowUp(String circleId, String readingId) =>
      '${measurementReadings(circleId)}/$readingId/follow-up';
}
