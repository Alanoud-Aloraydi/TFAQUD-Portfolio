import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The first and last name of the person being cared for.
class PatientNameFields extends StatelessWidget {
  const PatientNameFields({
    required this.state,
    required this.cubit,
    required this.firstName,
    required this.lastName,
    super.key,
  });

  final CreateCircleState state;
  final CreateCircleCubit cubit;
  final TextEditingController firstName;
  final TextEditingController lastName;

  @override
  Widget build(BuildContext context) {
    final String required = context.tr('common.field_required');
    return Column(
      children: <Widget>[
        LabeledTextField(
          label: context.tr('circles.patient_first_name'),
          controller: firstName,
          maxLength: NameLimits.name,
          onChanged: cubit.patientFirstNameChanged,
          errorText: state.showErrors && state.patientFirstName.trim().isEmpty
              ? required
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledTextField(
          label: context.tr('circles.patient_last_name'),
          controller: lastName,
          maxLength: NameLimits.name,
          textInputAction: TextInputAction.done,
          onChanged: cubit.patientLastNameChanged,
          errorText: state.showErrors && state.patientLastName.trim().isEmpty
              ? required
              : null,
        ),
      ],
    );
  }
}
