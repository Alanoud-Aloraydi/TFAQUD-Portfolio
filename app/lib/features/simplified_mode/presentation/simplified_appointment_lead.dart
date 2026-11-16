import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// What a visit's reminder opens with, by its day against [today] (the
/// patient's): «موعدك اليوم», «موعدك بكرة», «عندك موعد قريب», or, for one
/// whose day passed with nobody saying «حضرت», «موعدك كان». Calendar days,
/// never 24-hour steps: on a phone whose own clocks change, «بكرة» stays
/// tomorrow.
String simplifiedAppointmentLead(
  BuildContext context,
  CareAppointment visit,
  DateTime today,
) {
  final DateTime on = scheduleDay(visit.scheduledOn);
  return context.tr(
    on.isBefore(today)
        ? 'simplified_mode.appointment_was'
        : on == today
        ? 'simplified_mode.appointment_today'
        : on == addDays(today, 1)
        ? 'simplified_mode.appointment_tomorrow'
        : 'simplified_mode.appointment_coming',
  );
}
