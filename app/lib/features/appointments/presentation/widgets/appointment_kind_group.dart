import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_fields.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
