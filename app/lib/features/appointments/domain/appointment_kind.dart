/// What the visit is for; the form groups these by [AppointmentKindGroup].
enum AppointmentKind {
  followUp,
  newVisit,
  remote,
  emergency,
  test,
  imaging,
  eyeExam,
  hearingTest,
  surgery,
  physio,
  dialysis,
  therapySession,
  dressing,
  vaccine,
  checkup,
  dental,
  pharmacy,
  mental,
  speech,
  other;

  /// The wire name: «follow_up» for [followUp].
  String get code => name.replaceAllMapped(
    RegExp('[A-Z]'),
    (Match m) => '_${m[0]!.toLowerCase()}',
  );

  /// The kind with this wire name; [other] for one this app does not know.
  static AppointmentKind fromCode(String code) => values.firstWhere(
    (AppointmentKind kind) => kind.code == code,
    orElse: () => other,
  );
}
