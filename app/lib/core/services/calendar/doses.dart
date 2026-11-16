part of '../calendar_sync.dart';

/// The events of the medicine doses.
extension _CalendarDoses on _CalendarState {
  Future<bool> _collectDoses(
    ReminderCircle circle,
    Map<String, _DesiredEvent> desired,
  ) async {
    final result = await _medications.getPlans(circle.id);
    final plans = result.tryGetSuccess();
    if (plans == null) return false;
    final PatientClock clock = circle.clock;
    final DateTime ahead = _now().toUtc().add(_ahead);
    for (final plan in plans) {
      if (plan.isPreviousOn(clock.today())) continue;
      final version = plan.version;
      final DateTime from = _from(clock, version.effectiveFromOn, _now());
      for (final MedicationSchedule schedule in version.schedules) {
        // The time is part of the key: a dose moved to another time gets a
        // fresh event.
        final String key = _eventKey(
          circle,
          CalendarSyncCategory.doses,
          '${schedule.id}:${schedule.time}',
        );
        final String title = _texts.dose(circle.id, version.name);
        final DateTime start;
        final RecurrenceRule recurrence;
        switch (schedule.repeat) {
          // A monthly dose as one monthly event on its days of the month (1
          // to 28, which every month has).
          case ScheduleRepeat.monthly:
            final List<int> days = schedule.monthDays.toList()..sort();
            if (days.isEmpty) continue;
            start = _nextMonthDay(clock, from, schedule.time, days);
            recurrence = MonthlyRecurrence(
              daysOfMonth: days,
              end: UntilEnd(_until(start, ahead)),
            );
          // A dose every few days as one event repeating every that many
          // days («FREQ=DAILY;INTERVAL=3»), from its first day on or after
          // [from] on the count from the start of the treatment.
          case ScheduleRepeat.interval:
            final int? every = schedule.intervalDays;
            if (every == null || every < 1) continue;
            start = _nextIntervalDay(
              clock,
              from,
              schedule.time,
              version.startsOn,
              every,
            );
            recurrence = DailyRecurrence(
              interval: every,
              end: UntilEnd(_until(start, ahead)),
            );
          case ScheduleRepeat.weekly:
            start = _nextOccurrence(
              clock,
              from,
              schedule.time,
              schedule.weekdays,
            );
            recurrence = WeeklyRecurrence(
              daysOfWeek: schedule.weekdays.map(_dayOfWeek).toList(),
              end: UntilEnd(_until(start, ahead)),
            );
        }
        desired[key] = _DesiredEvent(
          title: title,
          zone: circle.timeZone,
          note: _texts.doseNote(),
          start: start,
          end: start.add(const Duration(minutes: 15)),
          reminders: const <Duration>[Duration.zero],
          recurrence: recurrence,
          until: _until(start, ahead),
        );
      }
    }
    return true;
  }
}
