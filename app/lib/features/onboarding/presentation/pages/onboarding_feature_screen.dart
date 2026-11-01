import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/inline_error.dart';
import 'package:app/core/widgets/labeled_text_field.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/core/widgets/step_header.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Name page of the account setup. Needs an [OnboardingCubit] above it.
class OnboardingFeatureScreen extends StatefulWidget {
  const OnboardingFeatureScreen({super.key});

  @override
  State<OnboardingFeatureScreen> createState() =>
      _OnboardingFeatureScreenState();
}

class _OnboardingFeatureScreenState extends State<OnboardingFeatureScreen> {
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
      // Text set by code is not cut by the field's limit, so it is cut here.
      final String shown = value.length > OnboardingCubit.maxDisplayNameLength
          ? value.substring(0, OnboardingCubit.maxDisplayNameLength)
          : value;
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
            builder: (BuildContext context, OnboardingState state) {
              final String requiredText = context.tr(
                'onboarding.field_required',
              );
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
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
                            // After the code page there is nothing to go back
                            // to, so the link is hidden.
                            onBack: context.canPop()
                                ? () => context.pop()
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          LabeledTextField(
                            label: context.tr('onboarding.first_name'),
                            controller: _first,
                            maxLength: OnboardingCubit.maxNameLength,
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
                            maxLength: OnboardingCubit.maxNameLength,
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
                            maxLength: OnboardingCubit.maxDisplayNameLength,
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
