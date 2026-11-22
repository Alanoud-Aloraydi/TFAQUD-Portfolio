import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_attend_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The badge of an appointment card: how far away it is when it is listed
/// as a plan ([relative]), otherwise its status: «ما أُكّد الحضور» once its
/// time passed without an answer, and «فائت» once it left «يحتاج انتباهك»
/// unanswered, as a dose does.
class AppointmentCardStatus extends StatelessWidget {
  const AppointmentCardStatus({
    super.key,
    required this.value,
    required this.relative,
    this.trailing,
  });

  final CareAppointment value;
  final bool relative;
  // The caret of a badge that opens a choice (AppointmentOutcomeBadge).
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final PatientClock clock = PatientClockScope.of(context);
    final int days = scheduleDay(value.scheduledOn)
        .difference(clock.today())
        .inDays;
    final bool missed = value.isMissedOn(clock.today());
    final bool unconfirmed =
        value.status == AppointmentStatus.scheduled &&
        value.scheduledAt.isBefore(clock.now());
    final String key = missed
        ? 'missed'
        : unconfirmed
        ? 'unconfirmed'
        : value.status.name;
    return StatusBadge(
      trailing: trailing,
      text: relative
          ? context.tr(_relativeKey(days), args: <String>['$days'])
          : context.tr('appointments.status.$key'),
      tone: relative
          ? (days == 0 ? StatusTone.attention : StatusTone.info)
          : missed
          ? StatusTone.danger
          : unconfirmed
          ? StatusTone.attention
          : _tone(value.status),
    );
  }

  static StatusTone _tone(AppointmentStatus status) => switch (status) {
    AppointmentStatus.scheduled => StatusTone.info,
    AppointmentStatus.completed => StatusTone.success,
    AppointmentStatus.cancelled => StatusTone.danger,
  };

  /// «اليوم», «بكرة», … for an appointment [days] away.
  static String _relativeKey(int days) => switch (days) {
    0 => 'appointments.today',
    1 => 'appointments.tomorrow',
    2 => 'appointments.in_two_days',
    _ => 'appointments.after_days',
  };
}
