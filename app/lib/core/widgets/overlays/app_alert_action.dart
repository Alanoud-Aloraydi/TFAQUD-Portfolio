/// One button of an [AppAlert].
class AppAlertAction<T> {
  const AppAlertAction({
    required this.label,
    this.value,
    this.primary = false,
    this.destructive = false,
  });

  final String label;

  /// What [showAppAlert] returns when this button is tapped.
  final T? value;

  /// The action the alert asks about, such as «حفظ»: an ink capsule. The
  /// others are light grey capsules.
  final bool primary;

  /// The action deletes something or cannot be undone, such as «حذف»,
  /// «تسجيل الخروج» or «تجاهل التغييرات»: a light grey capsule with its
  /// label in the error red (#A53636, 4.98:1 on the grey), as iOS draws a
  /// destructive action. It takes the place of the action the alert asks
  /// about.
  final bool destructive;

  /// Whether this is the action the alert asks about (not the way out).
  bool get isAction => primary || destructive;
}
