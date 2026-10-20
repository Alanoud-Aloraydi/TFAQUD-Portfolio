import 'package:app/core/navigation/routers.dart';
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
      _display.text = value;
      cubit.displayNameChanged(value);
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (BuildContext context, OnboardingState state) {
              final String requiredText = context.tr('onboarding.field_required');
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          StepHeader(
                            title: context.tr('onboarding.name_title'),
                            subtitle: context.tr('onboarding.name_subtitle'),
                            // After the code page there is nothing to go back
                            // to, so the link is hidden.
                            onBack: context.canPop() ? () => context.pop() : null,
                          ),
                          const SizedBox(height: 24),
                          LabeledTextField(
                            label: context.tr('onboarding.first_name'),
                            controller: _first,
                            autofocus: true,
                            onChanged: _onFirstNameChanged,
                            errorText:
                                state.showErrors &&
                                    state.firstName.trim().isEmpty
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: 16),
                          LabeledTextField(
                            label: context.tr('onboarding.last_name'),
                            controller: _last,
                            onChanged: context
                                .read<OnboardingCubit>()
                                .lastNameChanged,
                            errorText:
                                state.showErrors &&
                                    state.lastName.trim().isEmpty
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: 16),
                          LabeledTextField(
                            label: context.tr('onboarding.display_name'),
                            controller: _display,
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
                            const SizedBox(height: 16),
                            InlineError(messageKey: state.errorKey!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
