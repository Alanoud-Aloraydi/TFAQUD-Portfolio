import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_attend_window.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_added_by_group.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_companions_facts.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_status_change.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_when_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What an appointment card opens, in the groups of a plan's details:
/// «الموعد» (when, where or how, and that it shows in «اليوم» when
/// [appearsToday]), [otherVisits] of its booking, «المرافقون», «أضاف
/// الموعد» (the one person who added it), then for a manager «إلغاء الموعد»
/// last, the stop button of a medicine. «حضرت» is answered in «اليوم»
/// alone, by those who go; a missed visit asks nothing.
List<Widget> appointmentCardDetails(
  BuildContext context, {
  required CareAppointment value,
  required String circleId,
  required bool canManage,
  bool appearsToday = false,
  Widget? otherVisits,
}) {
  final PatientClock clock = PatientClockScope.of(context);
  final bool open =
      value.status == AppointmentStatus.scheduled &&
      !value.isMissedOn(clock.today());
  return <Widget>[
    appointmentWhenGroup(context, value, appearsToday: appearsToday),
    ?otherVisits,
    appointmentCompanionsFacts(context, value, circleId),
    ?appointmentAddedByGroup(context, value, circleId),
    if (canManage && open)
      StopButton(
        label: context.tr('appointments.cancel_appointment'),
        onPressed: () => changeAppointmentStatus(
          context,
          circleId,
          value,
          AppointmentStatus.cancelled,
        ),
      ),
  ];
}
