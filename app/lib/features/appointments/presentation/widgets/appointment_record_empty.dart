import 'package:app/core/navigation/care_item_routes.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// «السجل»'s visits when there are none, with «إضافة موعد طبي» when
/// [canAdd], as «الخطة» offers it.
class AppointmentRecordEmpty extends StatelessWidget {
  const AppointmentRecordEmpty({
    super.key,
    required this.circleId,
    required this.canAdd,
  });

  final String circleId;
  final bool canAdd;

  @override
  Widget build(BuildContext context) => EmptyStateNote.section(
    context.tr('appointments.no_records'),
    actionLabel: canAdd ? context.tr('add.appointment') : null,
    onAction: canAdd
        ? () => context.push<bool>(CareItemRoutes.newAppointment(circleId))
        : null,
  );
}
