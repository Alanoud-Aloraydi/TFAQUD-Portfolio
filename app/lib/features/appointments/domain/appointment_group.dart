import 'package:app/features/appointments/domain/appointment.dart';

/// A booking as one card: the visit the card shows ([shown]) and the
/// booking's other visits ([others], by date), which its details list. A
/// visit booked on its own is a booking of one, with no others.
class AppointmentGroup {
  const AppointmentGroup(this.shown, this.others);

  final CareAppointment shown;
  final List<CareAppointment> others;

  /// [visits] as cards, in their own order: each booking once, where the
  /// visit it shows sits. That is the booking's next visit still to come
  /// at [now], else its last one. Its others are taken from [all], every
  /// visit known, so a filter narrows the cards but never the list of a
  /// booking's other dates.
  static List<AppointmentGroup> of(
    List<CareAppointment> visits,
    List<CareAppointment> all,
    DateTime now,
  ) {
    final Map<String, CareAppointment> shown = <String, CareAppointment>{};
    for (final CareAppointment visit in visits) {
      final String? series = visit.seriesId;
      if (series == null) continue;
      final CareAppointment? best = shown[series];
      if (best == null || _before(visit, best, now)) shown[series] = visit;
    }
    return <AppointmentGroup>[
      for (final CareAppointment visit in visits)
        if (visit.seriesId == null)
          AppointmentGroup(visit, const <CareAppointment>[])
        else if (shown[visit.seriesId]?.id == visit.id)
          AppointmentGroup(
            visit,
            <CareAppointment>[
              for (final CareAppointment other in all)
                if (other.seriesId == visit.seriesId && other.id != visit.id)
                  other,
            ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
          ),
    ];
  }

  /// Whether [a] is the better visit to show than [b]: one still to come
  /// before any that passed, the sooner of two to come, the later of two
  /// that passed.
  static bool _before(CareAppointment a, CareAppointment b, DateTime now) {
    final bool aAhead = isUpcomingAppointment(a, now);
    final bool bAhead = isUpcomingAppointment(b, now);
    if (aAhead != bAhead) return aAhead;
    return aAhead
        ? a.scheduledAt.isBefore(b.scheduledAt)
        : a.scheduledAt.isAfter(b.scheduledAt);
  }
}

/// Whether [visit] is still to come at [now]: booked, and its time not
/// yet passed.
bool isUpcomingAppointment(CareAppointment visit, DateTime now) =>
    visit.status == AppointmentStatus.scheduled &&
    !visit.scheduledAt.isBefore(now);

/// The visits still ahead, soonest first: what «الخطة» lists.
List<CareAppointment> upcomingAppointments(
  List<CareAppointment> all,
  DateTime now,
) => <CareAppointment>[
  for (final CareAppointment visit in all)
    if (isUpcomingAppointment(visit, now)) visit,
]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

/// How many cards «الخطة» shows: one for each booking still ahead.
int upcomingBookings(List<CareAppointment> all, DateTime now) =>
    AppointmentGroup.of(upcomingAppointments(all, now), all, now).length;
