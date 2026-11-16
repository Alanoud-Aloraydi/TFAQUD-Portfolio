part of '../calendar_sync.dart';

/// The events of the appointments.
extension _CalendarAppointments on _CalendarState {
  Future<bool> _collectAppointments(
    ReminderCircle circle,
    Map<String, _DesiredEvent> desired,
  ) async {
    final List<CareAppointment> appointments;
    try {
      appointments = await _appointments.appointments(circle.id);
    } on Exception {
      return false;
    }
    final DateTime now = _now();
    for (final appointment in appointments) {
      if (appointment.status != AppointmentStatus.scheduled) continue;
      // The same people as its reminders: the patient and those going.
      if (!circle.remindsOfAppointment(appointment.companionIds)) continue;
      // The real moment of the patient's wall-clock time (not
      // [CareAppointment.scheduledAt], a wall time for ordering), so a
      // phone in any zone shows it at the right time.
      final DateTime at = circle.clock
          .momentOf(appointment.scheduledOn, appointment.time)
          .toLocal();
      if (at.isBefore(now)) continue;
      // The date and time are part of the key: an edited appointment gets a
      // new key, so the stale event is deleted and a fresh one created,
      // rather than silently keeping the old time.
      final String key = _eventKey(
        circle,
        CalendarSyncCategory.appointments,
        '${appointment.id}:'
        '${appointment.scheduledOn.toIso8601String()}:${appointment.time}',
      );
      final String place = appointment.place?.trim() ?? '';
      desired[key] = _DesiredEvent(
        title: _texts.appointment(circle.id, appointment),
        zone: circle.timeZone,
        note: _texts.appointmentNote(appointment),
        place: place.isEmpty ? null : place,
        start: at,
        end: at.add(const Duration(hours: 1)),
        // The same as its notifications: a day before, and two hours before.
        reminders: const <Duration>[Duration(days: 1), Duration(hours: 2)],
      );
    }
    return true;
  }
}
