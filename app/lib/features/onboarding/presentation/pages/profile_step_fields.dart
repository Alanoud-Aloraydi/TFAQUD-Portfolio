import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/pages/profile_birth_city.dart';
import 'package:app/features/onboarding/presentation/pages/profile_name_fields.dart';
import 'package:app/features/onboarding/presentation/pages/profile_step_header.dart';
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
