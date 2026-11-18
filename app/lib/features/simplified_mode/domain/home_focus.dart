/// What the simplified home's one card shows.
enum HomeFocus {
  /// A dose whose time passed unrecorded: «هل أخذت هذا الدواء؟».
  lateDose,

  /// The next task still to come, or a measurement whose time passed.
  task,

  /// Every task of today is resolved: «أحسنت! أنجزت كل شيء».
  allDone,

  /// Nothing is scheduled today.
  empty,
}
