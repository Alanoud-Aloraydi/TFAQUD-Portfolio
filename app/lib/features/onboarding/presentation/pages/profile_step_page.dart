import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/pages/profile_shown_changed.dart';
import 'package:app/features/onboarding/presentation/pages/profile_step_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The layout of the name step: the fields scroll, «متابعة» stays under them.
class ProfileStepPage extends StatelessWidget {
  const ProfileStepPage({
    super.key,
    required this.first,
    required this.last,
    required this.display,
    required this.onFirstNameChanged,
    required this.onDisplayNameChanged,
    required this.onBack,
    required this.onContinue,
  });

  final TextEditingController first;
  final TextEditingController last;
  final TextEditingController display;
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onDisplayNameChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            // The text fields keep their own text, so a typed letter
            // rebuilds the page only when it changes what is shown: an
            // error appearing or going, the picked date or city, saving.
            buildWhen: profileShownChanged,
            builder: (BuildContext context, OnboardingState state) {
              return ProfileStepBody(
                state: state,
                first: first,
                last: last,
                display: display,
                onFirstNameChanged: onFirstNameChanged,
                onDisplayNameChanged: onDisplayNameChanged,
                onBack: onBack,
                onContinue: onContinue,
              );
            },
          ),
        ),
      ),
    );
  }
}
