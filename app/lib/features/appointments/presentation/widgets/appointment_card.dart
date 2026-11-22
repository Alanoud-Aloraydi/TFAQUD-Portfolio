import 'package:app/core/widgets/layout/plan_item_card.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_body.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_edit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_heading.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_opened.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_status.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_icon.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_outcome_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One appointment as a plan card, as a medicine's is; a booking of several
/// dates is one card with its [others] in the details. «السجل» is not
/// [editable]: only «ورقة الزيارة» can still be written there, and how the
/// visit went changed from its badge.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.value,
    required this.circleId,
    required this.canManage,
    this.showRelativeDate = false,
    this.editable = true,
    this.others = const <CareAppointment>[],
    this.all = const <CareAppointment>[],
  });

  final CareAppointment value;
  final String circleId;
  final bool canManage;
  final bool showRelativeDate;
  final bool editable;
  final List<CareAppointment> others;
  final List<CareAppointment> all;

  @override
  Widget build(BuildContext context) {
    final bool manage = canManage && editable;
    return PlanItemCard(
      leading: Icon(appointmentKindIcon(value.kind)),
      title: appointmentCardTitle(context, value),
      subtitle: appointmentCardClinic(value),
      edit: appointmentCardEdit(context, value, circleId, manage: manage),
      // In «السجل» a manager changes how it went from its badge.
      status: canManage && !editable
          ? AppointmentOutcomeBadge(value: value, circleId: circleId)
          : AppointmentCardStatus(value: value, relative: showRelativeDate),
      start: appointmentCardStart(context, value),
      body: appointmentCardBody(
        context,
        value: value,
        all: all,
        circleId: circleId,
        canManage: canManage,
      ),
      detailsLabel: context.tr('appointments.details'),
      details: appointmentCardOpened(
        context,
        value: value,
        circleId: circleId,
        canManage: canManage,
        manage: manage,
        showRelativeDate: showRelativeDate,
        others: others,
        all: all,
      ),
    );
  }
}
