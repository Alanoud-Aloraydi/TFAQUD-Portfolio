import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/core/widgets/step_header.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/widgets/choice_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Last page of the account setup: "كيف تريد أن تبدأ؟". The "+" next to the
/// circles opens it again, to add another circle ([addingCircle]). That page
/// has a back link and no "تخطي الآن", because the account is already set up.
///
/// "أدير رعايتي بنفسي" continues to the three steps that create your own circle.
/// "أرعى شخصًا آخر" asks whether the patient uses the app. If the patient does,
/// the next page asks for the patient's phone number and sends a request. If the
/// patient does not, the next pages create the circle directly. The choice is
/// kept in [OnboardingCubit].
class StartScreen extends StatelessWidget {
  const StartScreen({super.key, this.addingCircle = false});

  final bool addingCircle;

  void _continue(BuildContext context, OnboardingState state) {
    if (state.careTarget == CareTarget.self) {
      context.push(Routes.createSelfCircle);
    } else if (state.patientUsesApp == true) {
      context.push(Routes.requestPatient);
    } else {
      context.push(Routes.createPatientCircle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (BuildContext context, OnboardingState state) {
              final OnboardingCubit cubit = context.read<OnboardingCubit>();
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          StepHeader(
                            title: context.tr('onboarding.start_title'),
                            // After the name page the link is hidden, as in the
                            // design. From the "+" it takes the user back.
                            onBack: addingCircle && context.canPop()
                                ? () => context.pop()
                                : null,
                          ),
                          const SizedBox(height: 16),
                          ChoiceCard(
                            icon: Icons.favorite_border,
                            title: context.tr('onboarding.self_title'),
                            hint: context.tr('onboarding.self_hint'),
                            selected: state.careTarget == CareTarget.self,
                            onTap: () => cubit.selectCareTarget(
                              CareTarget.self,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ChoiceCard(
                            icon: Icons.people_outline,
                            title: context.tr('onboarding.other_title'),
                            hint: context.tr('onboarding.other_hint'),
                            selected: state.careTarget == CareTarget.other,
                            onTap: () => cubit.selectCareTarget(
                              CareTarget.other,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.topCenter,
                            child: state.careTarget == CareTarget.other
                                ? _PatientQuestion(state: state)
                                : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: context.tr('common.continue'),
                    onPressed: state.canContinueStart
                        ? () => _continue(context, state)
                        : null,
                  ),
                  if (!addingCircle)
                    TextButton(
                      onPressed: () => context.go(Routes.today),
                      child: Text(
                        context.tr('onboarding.skip'),
                        style: text.labelLarge?.copyWith(color: AppColors.ink2),
                      ),
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

/// The follow-up question, shown under "another person", with a thin rail on
/// the start side that ties it to the option above.
class _PatientQuestion extends StatelessWidget {
  const _PatientQuestion({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final OnboardingCubit cubit = context.read<OnboardingCubit>();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 16),
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: 12),
        decoration: const BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: AppColors.brandTint, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.tr('onboarding.patient_question'),
              style: text.bodyMedium,
            ),
            const SizedBox(height: 12),
            ChoiceCard(
              icon: Icons.people_outline,
              title: context.tr('onboarding.patient_uses_title'),
              hint: context.tr('onboarding.patient_uses_hint'),
              selected: state.patientUsesApp == true,
              onTap: () => cubit.selectPatientUsesApp(usesApp: true),
            ),
            const SizedBox(height: 12),
            ChoiceCard(
              icon: Icons.person_outline,
              title: context.tr('onboarding.patient_no_title'),
              hint: context.tr('onboarding.patient_no_hint'),
              selected: state.patientUsesApp == false,
              onTap: () => cubit.selectPatientUsesApp(usesApp: false),
            ),
          ],
        ),
      ),
    );
  }
}
