import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/pages/profile_name_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The header and the fields of the name step: the names, the birth date and
/// the city; a refused birth date under it, any other refusal a toast.
class ProfileStepFields extends StatelessWidget {
  const ProfileStepFields({
    super.key,
    required this.state,
    required this.first,
    required this.last,
    required this.display,
    required this.onFirstNameChanged,
    required this.onDisplayNameChanged,
    required this.onBack,
  });

  final OnboardingState state;
  final TextEditingController first;
  final TextEditingController last;
  final TextEditingController display;
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onDisplayNameChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ProfileStepHeader(onBack: onBack),
        const SizedBox(height: AppSpacing.xl),
        ProfileNameFields(
          state: state,
          first: first,
          last: last,
          display: display,
          onFirstNameChanged: onFirstNameChanged,
          onDisplayNameChanged: onDisplayNameChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        ProfileBirthCity(state: state),
      ],
    );
  }
}

/// The header of the name step: step 1 of 2, and «رجوع» to the phone number.
class ProfileStepHeader extends StatelessWidget {
  const ProfileStepHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return StepHeader(
      // The first account set-up: the name, then where
      // to start.
      step: 1,
      totalSteps: 2,
      title: context.tr('onboarding.name_title'),
      subtitle: context.tr('onboarding.name_subtitle'),
      // Back to the phone number, signed out.
      onBack: onBack,
    );
  }
}
