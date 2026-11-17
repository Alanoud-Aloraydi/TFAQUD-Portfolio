import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_series.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_visit_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Under an appointment card's day and time: «الزيارة 2 من 6» when it is one
/// of several dates booked together (counted among [all]), and its
/// «ورقة الزيارة» once it was attended.
List<Widget> appointmentCardBody(
  BuildContext context, {
  required CareAppointment value,
  required List<CareAppointment> all,
  required String circleId,
  required bool canManage,
}) => <Widget>[
  if (AppointmentSeries.of(value, all) case final AppointmentSeries at)
    Text(
      context.tr(
        'appointments.visit_of_series',
        args: <String>['${at.index}', '${at.count}'],
      ),
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: context.tokens.textSecondary),
    ),
  if (value.status == AppointmentStatus.completed)
    AppointmentVisitButton(
      visit: value,
      circleId: circleId,
      canManage: canManage,
    ),
];
