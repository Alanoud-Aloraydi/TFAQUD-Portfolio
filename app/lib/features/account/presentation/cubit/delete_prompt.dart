/// The question the page asks while the account is being deleted. The server
/// asks for a choice only when it matters, so the questions come one at a time.
enum DeletePrompt {
  none,

  /// "Delete your account?" The first and last question.
  confirm,

  /// The account is the patient of a circle: delete it or keep it.
  patientChoice,

  /// The account is the only manager of a circle: delete it too, or stop.
  lastManager,
}
