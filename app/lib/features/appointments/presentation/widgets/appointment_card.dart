import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:app/core/widgets/layout/plan_item_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_body.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_details.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_status.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_other_visits.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One appointment as a plan card, as a medicine's is; a booking of several
/// dates is one card with its [others] in the details. «السجل» is not
/// [editable]: only «ورقة الزيارة» can still be written there.
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
    final bool open = value.status == AppointmentStatus.scheduled;
    final bool manage = canManage && editable;
    return PlanItemCard(
      leading: Icon(
        value.kind == AppointmentKind.remote
            ? CupertinoIcons.videocam
            : CupertinoIcons.calendar,
      ),
      title: Text(
        appointmentTitle(context, value),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: switch (appointmentClinic(value)) {
        final String clinic => Text(clinic),
        null => null,
      },
      edit: manage && open
          ? EditAction.pen(
              onPressed: () => context.push<bool>(
                Routes.editAppointment(circleId, value.id),
              ),
              tooltip: context.tr('appointments.edit'),
            )
          : null,
      status: AppointmentCardStatus(value: value, relative: showRelativeDate),
      start:
          '${appointmentDate(context, value.scheduledOn)}، '
          '${clockText(value.time)}',
      body: appointmentCardBody(
        context,
        value: value,
        all: all,
        circleId: circleId,
        canManage: canManage,
      ),
      detailsLabel: context.tr('appointments.details'),
      details: appointmentCardDetails(
        context,
        value: value,
        circleId: circleId,
        canManage: manage,
        appearsToday:
            showRelativeDate &&
            open &&
            !value.scheduledAt.isBefore(PatientClockScope.of(context).now()),
        otherVisits: appointmentOtherVisits(
          context,
          others: others,
          all: all,
          circleId: circleId,
          canManage: canManage,
        ),
      ),
    );
  }
}
