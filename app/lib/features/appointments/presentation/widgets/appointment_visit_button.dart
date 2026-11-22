import 'dart:async';

import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/care_item_routes.dart';

/// «ورقة الزيارة» of an attended [visit], opened for writing when
/// [canManage]: on its card, and beside each attended date of a booking in
/// «المواعيد الأخرى». Back from it, the visits are read again: whether its
/// paper has something in it decides whether «حضرت» can still change.
class AppointmentVisitButton extends StatelessWidget {
  const AppointmentVisitButton({
    super.key,
    required this.visit,
    required this.circleId,
    required this.canManage,
  });

  final CareAppointment visit;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppItemCard.touch),
      ),
      onPressed: () async {
        await context.push<void>(
          CareItemRoutes.appointmentVisit(circleId, visit.id),
          extra: canManage,
        );
        if (!context.mounted) return;
        unawaited(
          context.read<AppointmentsCubit>().load(circleId, silent: true),
        );
      },
      icon: const Icon(CupertinoIcons.doc_text),
      label: Text(context.tr('appointments.visit_title')),
    ),
  );
}
