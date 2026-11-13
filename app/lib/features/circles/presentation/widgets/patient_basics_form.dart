import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/patient_birth_field.dart';
import 'package:app/features/circles/presentation/widgets/patient_city_field.dart';
import 'package:app/features/circles/presentation/widgets/patient_form_header.dart';
import 'package:app/features/circles/presentation/widgets/patient_name_fields.dart';
import 'package:flutter/material.dart';

/// Everything on the page of a person without the app, above the create
/// button: the title, one line on what the circle is for, and the fields.
class PatientBasicsForm extends StatelessWidget {
  const PatientBasicsForm({
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
    const SizedBox gap = SizedBox(height: AppSpacing.lg);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PatientFormHeader(),
          PatientNameFields(
            state: state,
            cubit: cubit,
            firstName: firstName,
            lastName: lastName,
          ),
          gap,
          PatientBirthField(state: state, cubit: cubit),
          gap,
          PatientCityField(state: state, cubit: cubit),
          if (state.errorKey != null) ...<Widget>[
            gap,
            InlineError(messageKey: state.errorKey!),
          ],
        ],
      ),
    );
  }
}
