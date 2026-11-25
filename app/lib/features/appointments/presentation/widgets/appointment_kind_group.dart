import 'dart:async';

import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_fields.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «الموعد»: the kind of visit, its own name when it is «أخرى», and the
/// clinic.
class AppointmentKindGroup extends StatelessWidget {
  const AppointmentKindGroup({super.key, required this.form});

  final AppointmentFormFields form;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      header: context.tr('appointments.appointment_group'),
      children: [
        InsetBlock(
          semanticLabel: context.tr('appointments.type'),
          child: AppointmentKindChoices(
            selected: form.kind,
            onSelected: (kind) => form.update(() {
              form.kind = kind;
              form.errorKey = null;
            }),
          ),
        ),
        if (form.kind == AppointmentKind.other)
          FieldWithError(
            error: form.fieldError('appointments.kind_required'),
            child: InsetTextRow(
              label: context.tr('appointments.custom_kind'),
              controller: form.otherKind,
              maxLength: 80,
              onChanged: (_) => form.update(() => form.errorKey = null),
            ),
          ),
        InsetTextRow(
          label: context.tr('appointments.clinic_field'),
          hint: context.tr('appointments.clinic_hint'),
          controller: form.clinic,
          maxLength: 80,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

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
