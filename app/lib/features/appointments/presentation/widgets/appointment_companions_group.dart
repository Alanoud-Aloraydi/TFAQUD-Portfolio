import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_state.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_fields.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_companion_chips.dart';
import 'package:app/features/appointments/presentation/widgets/companion_hint.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
