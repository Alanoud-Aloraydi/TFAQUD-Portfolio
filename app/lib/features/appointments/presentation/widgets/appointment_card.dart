import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:app/core/widgets/layout/plan_item_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_details.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One appointment as a plan card, built as a medicine's and a
/// measurement's are: its clinic, kind and status with the pencil, the day
/// and time on the line that opens «تفاصيل الموعد», and in them where it is,
/// who goes, who added or changed it, and the actions. [showRelativeDate] is
/// for the plan tab, where the status counts the days and the details say
/// it will appear in «اليوم»; the record tab leaves both out.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.value,
    required this.circleId,
    required this.canManage,
    this.showRelativeDate = false,
  });

  final CareAppointment value;
  final String circleId;
  final bool canManage;
  final bool showRelativeDate;

  @override
  Widget build(BuildContext context) {
    final bool open = value.status == AppointmentStatus.scheduled;
    final bool upcoming =
        open &&
        !value.scheduledAt.isBefore(PatientClockScope.of(context).now());
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
      subtitle: Text(appointmentKindTitle(context, value)),
      edit: canManage && open
          ? PlanEditButton(
              onPressed: () => context.push<bool>(
                Routes.editAppointment(circleId, value.id),
              ),
              tooltip: context.tr('appointments.edit'),
            )
          : null,
      status: AppointmentCardStatus(value: value, relative: showRelativeDate),
      // The day and time sit on the line that opens the details, as a
      // plan's start does; where, who goes and the rest are in the details.
      start:
          '${appointmentDate(context, value.scheduledOn)} · '
          '${clockText(value.time)}',
      body: <Widget>[
        if (value.status == AppointmentStatus.completed)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppItemCard.touch),
              ),
              onPressed: () => context.push<void>(
                Routes.appointmentVisit(circleId, value.id),
                extra: canManage,
              ),
              icon: const Icon(CupertinoIcons.doc_text),
              label: Text(context.tr('appointments.visit_title')),
            ),
          ),
      ],
      detailsLabel: context.tr('appointments.details'),
      details: appointmentCardDetails(
        context,
        value: value,
        circleId: circleId,
        canManage: canManage,
        appearsToday: showRelativeDate && upcoming,
      ),
    );
  }
}
