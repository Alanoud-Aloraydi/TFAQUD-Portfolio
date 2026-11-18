import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Where the visit is held: video or phone for a remote visit, otherwise
/// the place typed in.
class AppointmentPlaceBlock extends StatelessWidget {
  const AppointmentPlaceBlock({super.key, required this.form});

  final AppointmentFormFields form;

  @override
  Widget build(BuildContext context) {
    if (form.kind == AppointmentKind.remote) {
      return InsetBlock(
        semanticLabel: context.tr('appointments.remote_method'),
        child: GlassSegmentedControl<String>(
          segments: {
            'video': context.tr('appointments.video'),
            'phone': context.tr('appointments.phone'),
          },
          selected: form.remoteMethod,
          onChanged: (value) => form.update(() => form.remoteMethod = value),
        ),
      );
    }
    return FieldWithError(
      error: form.fieldError('appointments.place_required'),
      child: InsetTextRow(
        label: context.tr('appointments.place'),
        hint: context.tr('appointments.place_hint'),
        controller: form.place,
        maxLength: 160,
        maxLines: 3,
        onChanged: (_) => form.update(() => form.errorKey = null),
      ),
    );
  }
}
