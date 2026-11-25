import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/app/services/signed_out.dart';
import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/pages/profile_step_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

/// Where the name step goes: on to the start step, back to the phone number
/// signed out, or to the sign-in when it ended.
mixin ProfileStepLeaving<T extends StatefulWidget> on State<T> {
  Future<void> continueToStart() async {
    final bool saved = await context.read<OnboardingCubit>().saveProfile();
    if (!saved || !mounted) return;
    AppToast.show(context, 'toast.profile_saved');
    unawaited(context.push(Routes.onboardingStart));
  }

  /// «رجوع»: the sign-in is already made with the code, so going back to
  /// the phone number (to correct it) ends it. A new code is needed to come
  /// back, so the person confirms first.
  Future<void> confirmBack() async {
    final bool? leave = await showAppAlert<bool>(
      context,
      title: context.tr('onboarding.back_title'),
      message: context.tr('onboarding.back_message'),
      actions: <AppAlertAction<bool>>[
        AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
        AppAlertAction<bool>(
          label: context.tr('common.back'),
          value: true,
          primary: true,
        ),
      ],
    );
    if (leave == true && mounted) {
      unawaited(context.read<AuthCubit>().signOut());
    }
  }

  /// Leaves for the phone number page once the sign-out is done, or shows
  /// why it failed.
  void signedOut(BuildContext context, AuthState state) {
    if (state is AuthErrorState) {
      AppToast.show(context, state.messageKey, kind: ToastKind.error);
      return;
    }
    if (state is AuthSignedOutState) {
      unawaited(forgetSignedOutPerson());
      context.go(Routes.authPhone);
    }
  }

  /// The save found the sign-in ended (revoked or expired): nothing of the
  /// person stays on the phone, and the sign-in starts again.
  void sessionEnded(BuildContext context, OnboardingState state) {
    unawaited(forgetSignedOutPerson());
    context.go(Routes.auth);
  }
}

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

/// Whether [current] shows anything different from [previous].
bool profileShownChanged(OnboardingState previous, OnboardingState current) {
  bool blank(String value) => value.trim().isEmpty;
  return previous.showErrors != current.showErrors ||
      previous.status != current.status ||
      previous.errorKey != current.errorKey ||
      previous.birthDate != current.birthDate ||
      previous.city != current.city ||
      blank(previous.firstName) != blank(current.firstName) ||
      blank(previous.lastName) != blank(current.lastName) ||
      blank(previous.displayName) != blank(current.displayName);
}

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
