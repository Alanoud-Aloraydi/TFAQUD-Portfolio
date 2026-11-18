import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_state.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_fields.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_companions_group.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_group.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_time_place_group.dart';
import 'package:flutter/material.dart';

/// The appointment form's groups, one under the other.
class AppointmentFormBody extends StatelessWidget {
  const AppointmentFormBody({
    super.key,
    required this.form,
    required this.companions,
  });

  final AppointmentFormFields form;
  final AppointmentCompanionsState companions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppointmentKindGroup(form: form),
        const SizedBox(height: AppSpacing.xl),
        AppointmentTimePlaceGroup(form: form),
        const SizedBox(height: AppSpacing.xl),
        AppointmentCompanionsGroup(form: form, companions: companions),
      ],
    );
  }
}
