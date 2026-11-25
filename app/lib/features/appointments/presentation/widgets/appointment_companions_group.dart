import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_fields.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_companion_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// «المرافقون»: the circle's people who may go with the patient, and who
/// the visit reminds.
class AppointmentCompanionsGroup extends StatelessWidget {
  const AppointmentCompanionsGroup({
    super.key,
    required this.form,
    required this.companions,
  });

  final AppointmentFormFields form;
  final AppointmentCompanionsState companions;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      header: context.tr('appointments.companion'),
      footer: companionHint(context, companions, form.companionIds),
      children: [
        AppointmentCompanionChips(
          circleId: form.widget.circleId,
          state: companions,
          chosen: form.companionIds,
          onToggle: (String id, bool selected) => form.update(() {
            selected ? form.companionIds.add(id) : form.companionIds.remove(id);
          }),
        ),
      ],
    );
  }
}

/// The note under «المرافقون»: who the visit reminds. The patient and the
/// companions [chosen]; for a patient without a phone, the companions, or
/// the circle's leader when nobody goes with them.
String companionHint(
  BuildContext context,
  AppointmentCompanionsState state,
  Set<String> chosen,
) => context.tr(
  state.patientHasPhone
      ? 'appointments.companion_hint'
      : chosen.isEmpty
      ? 'appointments.companion_hint_leader'
      : 'appointments.companion_hint_no_phone',
);

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
