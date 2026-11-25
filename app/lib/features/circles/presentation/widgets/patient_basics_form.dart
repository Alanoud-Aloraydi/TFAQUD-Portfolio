import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/patient_city_field.dart';
import 'package:app/features/circles/presentation/widgets/patient_name_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Everything on the page of a person without the app, above the create
/// button: the title, one line on what the circle is for, and the fields.
/// A refusal of the birth date is under its field; any other is a toast.
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
          ErrorToast(
            errorKey: isBirthDateError(state.errorKey) ? null : state.errorKey,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// The title of the page of a person without the app, and one line on what
/// the circle is for. Nothing else is explained on the page.
class PatientFormHeader extends StatelessWidget {
  const PatientFormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StepHeader(
          title: context.tr('circles.patient_title'),
          subtitle: context.tr('circles.patient_subtitle'),
          onBack: context.canPop() ? () => context.pop() : null,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
