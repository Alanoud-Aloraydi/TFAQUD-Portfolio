import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/pages/profile_step_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The fields of the name step, scrolling, and «متابعة» staying under them.
class ProfileStepBody extends StatelessWidget {
  const ProfileStepBody({
    super.key,
    required this.state,
    required this.first,
    required this.last,
    required this.display,
    required this.onFirstNameChanged,
    required this.onDisplayNameChanged,
    required this.onBack,
    required this.onContinue,
  });

  final OnboardingState state;
  final TextEditingController first;
  final TextEditingController last;
  final TextEditingController display;
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onDisplayNameChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ProfileStepFields(
              state: state,
              first: first,
              last: last,
              display: display,
              onFirstNameChanged: onFirstNameChanged,
              onDisplayNameChanged: onDisplayNameChanged,
              onBack: onBack,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: context.tr('common.continue'),
          isLoading: state.status == OnboardingStatus.saving,
          onPressed: onContinue,
        ),
      ],
    );
  }
}
