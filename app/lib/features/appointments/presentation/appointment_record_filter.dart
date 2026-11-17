import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_group.dart';

/// Which appointments «السجل» shows: every one, the coming ones, or the
/// ones already behind.
enum AppointmentRecordFilter {
  all,
  upcoming,
  previous;

  /// Whether an appointment belongs in the list; [upcoming] is one still
  /// scheduled and not yet past.
  bool keeps({required bool isUpcoming}) => switch (this) {
    all => true,
    AppointmentRecordFilter.upcoming => isUpcoming,
    previous => !isUpcoming,
  };

  /// The appointments of [all] it keeps, newest first.
  List<CareAppointment> pick(List<CareAppointment> all, DateTime now) =>
      <CareAppointment>[
        for (final CareAppointment item in all)
          if (keeps(isUpcoming: isUpcomingAppointment(item, now))) item,
      ]..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  /// The key of its words, under `appointments.filters`.
  String get labelKey => 'appointments.filters.$name';
}
