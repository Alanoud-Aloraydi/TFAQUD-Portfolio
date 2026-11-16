/// Which circle the page creates. Each flow has its own page and its own
/// call; the health answers are filled later in the medical file.
enum CircleFlow {
  /// A circle for the person's own care (PROFILE-01): they are the patient.
  self,

  /// A circle for a patient who does not use the app (PROFILE-01B): the
  /// person types the patient's names.
  patient,

  /// The patient agreed to a request and gives the basic data (PROFILE-01C).
  /// The name comes from the account; the patient names the circle.
  approved,
}
