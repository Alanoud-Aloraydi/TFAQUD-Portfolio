/// The medication plans of one circle, their doses and their photos.
abstract final class MedicationEndpoints {
  static String medicationPlans(String circleId) =>
      '/circles/$circleId/medication-plans';

  static String medicationPlan(String circleId, String planId) =>
      '${medicationPlans(circleId)}/$planId';
  static String medicationPhoto(String circleId, String planId) =>
      '${medicationPlan(circleId, planId)}/photo';

  static String discontinueMedication(String circleId, String planId) =>
      '${medicationPlan(circleId, planId)}/stop';

  static String cancelPendingMedication(String circleId, String planId) =>
      '${medicationPlan(circleId, planId)}/cancel-pending';

  static String medicationOccurrences(String circleId) =>
      '/circles/$circleId/medication-occurrences';

  /// «سجّل جرعة الآن»: POST one, GET those of some days.
  static String medicationExtraDoses(String circleId) =>
      '/circles/$circleId/medication-extra-doses';

  static String medicationDoseRecord(
    String circleId,
    String scheduleId,
    String scheduledOn,
  ) =>
      '/circles/$circleId/medication-dose-records/'
      '$scheduleId/$scheduledOn';
}
