/// What the phone allows the app to do with one of its features, read from
/// the system and never from a saved choice of ours: the person can change
/// it in the phone's Settings while the app is away.
enum AppPermission {
  /// Never asked yet, so asking still shows the system's question.
  notAsked,

  /// Allowed in full.
  granted,

  /// Allowed in part. On iOS the calendar can be «Add Only»: the app writes
  /// events but cannot delete the ones it no longer wants.
  partial,

  /// Refused. iOS asks only once, so the person must change it in Settings.
  denied;

  /// Whether the feature works at all with this answer.
  bool get usable => this == granted || this == partial;

  /// Whether asking would still show the system's question.
  bool get askable => this == notAsked || this == partial;
}
