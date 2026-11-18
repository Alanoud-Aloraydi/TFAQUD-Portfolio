/// Where a reading falls in its normal range. The server judges every
/// reading by fixed ranges (by meal state and the patient's conditions in
/// the medical file); the app shows the same four levels.
enum MeasurementLevel {
  /// Below the normal range.
  low,
  normal,

  /// Above normal, not high yet: «أعلى من الطبيعي» / «طبيعي مرتفع».
  elevated,
  high;

  /// `low`, `normal`, `elevated` or `high` as the server sends it; null for
  /// a skip or a value this app does not know.
  static MeasurementLevel? fromWire(Object? value) =>
      MeasurementLevel.values.asNameMap()[value];
}
