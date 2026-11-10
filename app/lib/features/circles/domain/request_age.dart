import 'package:app/core/utils/patient_clock.dart';

/// How long ago a request was sent, for the account page ("قبل يومين").
abstract class RequestAge {
  RequestAge._();

  /// Whole calendar days between the day [sentAt] was sent and today, both
  /// read on the patient's [clock] (never the phone's zone), never below
  /// zero. Null when the server did not say when the request was sent.
  static int? days(DateTime? sentAt, PatientClock clock) {
    if (sentAt == null) return null;
    final DateTime sentDay = clock.today(sentAt);
    final DateTime today = clock.today();
    final int days = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(sentDay.year, sentDay.month, sentDay.day)).inDays;
    return days < 0 ? 0 : days;
  }
}
