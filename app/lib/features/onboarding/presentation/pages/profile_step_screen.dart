import 'dart:async';

import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/signed_out.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/forms/birth_date_city_fields.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_state.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
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

class _ProfileStepScreenState extends State<ProfileStepScreen> {
  final TextEditingController _first = TextEditingController();
  final TextEditingController _last = TextEditingController();
  final TextEditingController _display = TextEditingController();

  /// Until the user edits the display name, it follows the first name.
  bool _displayEdited = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _display.dispose();
    super.dispose();
  }

  void _onFirstNameChanged(String value) {
    final OnboardingCubit cubit = context.read<OnboardingCubit>();
    cubit.firstNameChanged(value);
    if (!_displayEdited) {
      // Text set by code is not cut by the field's limit, so it is cut here,
      // in code points as the server counts, never inside an emoji.
      final String shown = limitCodePoints(value, NameLimits.displayName);
      _display.text = shown;
      cubit.displayNameChanged(shown);
    }
  }

  void _onDisplayNameChanged(String value) {
    _displayEdited = true;
    context.read<OnboardingCubit>().displayNameChanged(value);
  }

  Future<void> _continue() async {
    final bool saved = await context.read<OnboardingCubit>().saveProfile();
    if (saved && mounted) context.push(Routes.onboardingStart);
  }

  /// «رجوع»: the sign-in is already made with the code, so going back to
  /// the phone number (to correct it) ends it. A new code is needed to come
  /// back, so the person confirms first.
  Future<void> _confirmBack() async {
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
  void _signedOut(BuildContext context, AuthState state) {
    if (state is AuthErrorState) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(state.messageKey))));
      return;
    }
    if (state is AuthSignedOutState) {
      unawaited(forgetSignedOutPerson());
      context.go(Routes.authPhone);
    }
  }

  /// Whether [current] shows anything different from [previous].
  static bool _shownChanged(OnboardingState previous, OnboardingState current) {
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(listener: _signedOut),
        BlocListener<OnboardingCubit, OnboardingState>(
          listenWhen: (previous, current) =>
              current.sessionEnded && !previous.sessionEnded,
          listener: _sessionEnded,
        ),
      ],
      child: _page(context),
    );
  }

  /// The save found the sign-in ended (revoked or expired): nothing of the
  /// person stays on the phone, and the sign-in starts again.
  void _sessionEnded(BuildContext context, OnboardingState state) {
    unawaited(forgetSignedOutPerson());
    context.go(Routes.auth);
  }

  Widget _page(BuildContext context) {
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
            buildWhen: _shownChanged,
            builder: (BuildContext context, OnboardingState state) {
              final String requiredText = context.tr('common.field_required');
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          StepHeader(
                            // The first account set-up: the name, then where
                            // to start.
                            step: 1,
                            totalSteps: 2,
                            title: context.tr('onboarding.name_title'),
                            subtitle: context.tr('onboarding.name_subtitle'),
                            // Back to the phone number, signed out.
                            onBack: _confirmBack,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          LabeledTextField(
                            label: context.tr('onboarding.first_name'),
                            controller: _first,
                            maxLength: NameLimits.name,
                            autofocus: true,
                            onChanged: _onFirstNameChanged,
                            errorText:
                                state.showErrors &&
                                    state.firstName.trim().isEmpty
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          LabeledTextField(
                            label: context.tr('onboarding.last_name'),
                            controller: _last,
                            maxLength: NameLimits.name,
                            onChanged: context
                                .read<OnboardingCubit>()
                                .lastNameChanged,
                            errorText:
                                state.showErrors &&
                                    state.lastName.trim().isEmpty
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          LabeledTextField(
                            label: context.tr('onboarding.display_name'),
                            controller: _display,
                            maxLength: NameLimits.displayName,
                            textInputAction: TextInputAction.done,
                            onChanged: _onDisplayNameChanged,
                            helperText: context.tr(
                              'onboarding.display_name_hint',
                            ),
                            errorText:
                                state.showErrors &&
                                    state.displayName.trim().isEmpty
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          BirthDateCityFields(
                            birthDate: state.birthDate,
                            city: state.city,
                            onBirthDate: context
                                .read<OnboardingCubit>()
                                .birthDateChanged,
                            onCity: context.read<OnboardingCubit>().cityChanged,
                            showErrors: state.showErrors,
                          ),
                          if (state.errorKey != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.lg),
                            InlineError(messageKey: state.errorKey!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PillButton(
                    label: context.tr('common.continue'),
                    isLoading: state.status == OnboardingStatus.saving,
                    onPressed: _continue,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
