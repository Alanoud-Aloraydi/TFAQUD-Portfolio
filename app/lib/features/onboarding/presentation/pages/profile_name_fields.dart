import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
