import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/pages/profile_step_leaving.dart';
import 'package:app/features/onboarding/presentation/pages/profile_step_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 1 of 2 of the first account set-up («خلّنا نتعرّف عليك»): the
/// names, the birth date and the city.
///
/// They are asked once here, so a circle for the person's own care needs
/// only its name. Flow: this page → [OnboardingCubit.saveProfile] →
/// `ProfileUseCase` → PUT /api/v1/accounts/me/profile, then the start step
/// (`StartScreen`). «رجوع» signs out through [AuthCubit], after a
/// confirmation, and returns to the phone number page. Needs an
/// [OnboardingCubit] and an [AuthCubit] above it (the onboarding
/// `ShellRoute`).
class ProfileStepScreen extends StatefulWidget {
  const ProfileStepScreen({super.key});

  @override
  State<ProfileStepScreen> createState() => _ProfileStepScreenState();
}

class _ProfileStepScreenState extends State<ProfileStepScreen>
    with ProfileStepNames, ProfileStepLeaving {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(listener: signedOut),
        BlocListener<OnboardingCubit, OnboardingState>(
          listenWhen: (previous, current) =>
              current.sessionEnded && !previous.sessionEnded,
          listener: sessionEnded,
        ),
      ],
      child: ProfileStepPage(
        first: first,
        last: last,
        display: display,
        onFirstNameChanged: onFirstNameChanged,
        onDisplayNameChanged: onDisplayNameChanged,
        onBack: confirmBack,
        onContinue: continueToStart,
      ),
    );
  }
}

/// The three name fields of the name step: their texts, and the display name
/// that follows the first name until the person edits it.
mixin ProfileStepNames<T extends StatefulWidget> on State<T> {
  final TextEditingController first = TextEditingController();
  final TextEditingController last = TextEditingController();
  final TextEditingController display = TextEditingController();

  /// Until the user edits the display name, it follows the first name.
  bool _displayEdited = false;

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    display.dispose();
    super.dispose();
  }

  void onFirstNameChanged(String value) {
    final OnboardingCubit cubit = context.read<OnboardingCubit>();
    cubit.firstNameChanged(value);
    if (!_displayEdited) {
      // Text set by code is not cut by the field's limit, so it is cut here,
      // in code points as the server counts, never inside an emoji.
      final String shown = limitCodePoints(value, NameLimits.displayName);
      display.text = shown;
      cubit.displayNameChanged(shown);
    }
  }

  void onDisplayNameChanged(String value) {
    _displayEdited = true;
    context.read<OnboardingCubit>().displayNameChanged(value);
  }
}
