import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/forms/birth_date_city_fields.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// The first name, the last name and the display name of the name step.
class ProfileNameFields extends StatelessWidget {
  const ProfileNameFields({
    super.key,
    required this.state,
    required this.first,
    required this.last,
    required this.display,
    required this.onFirstNameChanged,
    required this.onDisplayNameChanged,
  });

  final OnboardingState state;
  final TextEditingController first;
  final TextEditingController last;
  final TextEditingController display;
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onDisplayNameChanged;

  @override
  Widget build(BuildContext context) {
    // «هذا الحقل مطلوب» under an empty name, once saving was tried.
    String? missing(String value) => state.showErrors && value.trim().isEmpty
        ? context.tr('common.field_required')
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LabeledTextField(
          label: context.tr('onboarding.first_name'),
          controller: first,
          maxLength: NameLimits.name,
          autofocus: true,
          onChanged: onFirstNameChanged,
          errorText: missing(state.firstName),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledTextField(
          label: context.tr('onboarding.last_name'),
          controller: last,
          maxLength: NameLimits.name,
          onChanged: context.read<OnboardingCubit>().lastNameChanged,
          errorText: missing(state.lastName),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledTextField(
          label: context.tr('onboarding.display_name'),
          controller: display,
          maxLength: NameLimits.displayName,
          textInputAction: TextInputAction.done,
          onChanged: onDisplayNameChanged,
          helperText: context.tr('onboarding.display_name_hint'),
          errorText: missing(state.displayName),
        ),
      ],
    );
  }
}

/// The birth date and the city of the name step. A refused birth date is
/// said under it; any other refusal of the save is a toast.
class ProfileBirthCity extends StatelessWidget {
  const ProfileBirthCity({super.key, required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final OnboardingCubit cubit = context.read<OnboardingCubit>();
    final String? birthError = isBirthDateError(state.errorKey)
        ? context.tr(state.errorKey!)
        : null;
    return ErrorToast(
      errorKey: birthError == null ? state.errorKey : null,
      child: BirthDateCityFields(
        birthDate: state.birthDate,
        city: state.city,
        onBirthDate: cubit.birthDateChanged,
        onCity: cubit.cityChanged,
        showErrors: state.showErrors,
        birthDateError: birthError,
      ),
    );
  }
}
