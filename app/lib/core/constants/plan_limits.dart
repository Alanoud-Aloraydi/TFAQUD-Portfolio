/// Limits shared by every kind of care plan. The API schemas and the
/// database use the same numbers (`backend/app/plan_limits.py`).
abstract class PlanLimits {
  PlanLimits._();

  /// The shortest and longest wait, in minutes, after a dose's or reading's
  /// time before it counts as missed.
  static const int minMissedAfterMinutes = 5;
  static const int maxMissedAfterMinutes = 360;
  static const int defaultMissedAfterMinutes = 60;

  /// Whether [minutes] is a wait the server accepts.
  static bool isValidMissedAfter(int? minutes) =>
      minutes != null &&
      minutes >= minMissedAfterMinutes &&
      minutes <= maxMissedAfterMinutes;
}
