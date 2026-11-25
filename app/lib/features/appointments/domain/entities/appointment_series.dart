import 'package:app/features/appointments/domain/entities/appointment.dart';

/// Where a visit sits in the booking it was saved with: «الزيارة 2 من 6».
/// Worked out from the visits on hand rather than asked of the server,
/// which stores only the booking a visit belongs to.
class AppointmentSeries {
  const AppointmentSeries(this.index, this.count);

  /// Its place in the booking, counted from one.
  final int index;

  /// How many visits the booking holds.
  final int count;

  /// Where [value] sits among [all]; null for a visit on its own, and for
  /// a booking whose other visits are not in [all] (another month, say),
  /// where «الزيارة 1 من 1» would say something untrue.
  static AppointmentSeries? of(
    CareAppointment value,
    List<CareAppointment> all,
  ) {
    final String? series = value.seriesId;
    if (series == null) return null;
    final List<CareAppointment> booked =
        <CareAppointment>[
          for (final CareAppointment item in all)
            if (item.seriesId == series) item,
        ]..sort(
          (CareAppointment a, CareAppointment b) =>
              a.scheduledOn.compareTo(b.scheduledOn),
        );
    if (booked.length < 2) return null;
    final int at = booked.indexWhere(
      (CareAppointment item) => item.id == value.id,
    );
    return at < 0 ? null : AppointmentSeries(at + 1, booked.length);
  }
}

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
