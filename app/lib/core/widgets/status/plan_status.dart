/// Where a care plan stands on a given day, the same for every kind of plan.
enum PlanStatus {
  /// In effect today.
  active,

  /// Saved, but its first day has not come yet.
  scheduled,

  /// Reached its end date.
  completed,

  /// Stopped by someone before its end date.
  stopped;

  /// The translation key of the label shown on the badge.
  String get labelKey => 'plan_status.$name';
}
