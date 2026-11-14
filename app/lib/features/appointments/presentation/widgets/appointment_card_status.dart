import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The badge of an appointment card: how far away it is when it is listed
/// as a plan ([relative]), otherwise its status, or «لم يتأكد» once its time
/// passed without an answer.
class AppointmentCardStatus extends StatelessWidget {
  const AppointmentCardStatus({
    super.key,
    required this.value,
    required this.relative,
  });

  final CareAppointment value;
  final bool relative;

  @override
  Widget build(BuildContext context) {
    final PatientClock clock = PatientClockScope.of(context);
    final int days = scheduleDay(value.scheduledOn)
        .difference(clock.today())
        .inDays;
    final bool unconfirmed =
        value.status == AppointmentStatus.scheduled &&
        value.scheduledAt.isBefore(clock.now());
    return StatusBadge(
      text: relative
          ? context.tr(_relativeKey(days), args: <String>['$days'])
          : context.tr(
              unconfirmed
                  ? 'appointments.status.unconfirmed'
                  : 'appointments.status.${value.status.name}',
            ),
      tone: relative
          ? (days == 0 ? StatusTone.attention : StatusTone.info)
          : unconfirmed
          ? StatusTone.attention
          : _tone(value.status),
    );
  }

  static StatusTone _tone(AppointmentStatus status) => switch (status) {
    AppointmentStatus.scheduled => StatusTone.info,
    AppointmentStatus.completed => StatusTone.success,
    AppointmentStatus.cancelled => StatusTone.muted,
  };

  /// «اليوم», «بكرة», … for an appointment [days] away.
  static String _relativeKey(int days) => switch (days) {
    0 => 'appointments.today',
    1 => 'appointments.tomorrow',
    2 => 'appointments.in_two_days',
    _ => 'appointments.after_days',
  };
}
