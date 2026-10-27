/// How long ago a request was sent, for the account page ("قبل يومين").
abstract class RequestAge {
  RequestAge._();

  /// Whole days between [sentAt] and [now], never below zero. Null when the
  /// server did not say when the request was sent.
  static int? days(DateTime? sentAt, DateTime now) {
    if (sentAt == null) return null;
    final int days = now.difference(sentAt).inDays;
    return days < 0 ? 0 : days;
  }
}
