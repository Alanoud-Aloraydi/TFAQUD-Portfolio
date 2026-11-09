import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/pending_invites_section.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/widgets/choice_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Last page of the account setup: "لديك دعوة؟ أم تبدأ دائرتك؟". The "+" next to the
/// circles opens it again, to add another circle ([addingCircle]). That page
/// has no "تخطي الآن", because the account is already set up.
///
/// Above the choice, a brand-new person's own pending invitations show up
/// right away ([PendingInvitesSection]): someone may have invited them
/// before they ever opened the app, so answering it here picks their circle
/// directly, with no need to choose "أرعى شخصًا آخر" at all.
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
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
                            // Step 2 of the first set-up; from the "+" it is
                            // one page, with no steps.
                            step: addingCircle ? null : 2,
                            totalSteps: addingCircle ? null : 2,
                            title: context.tr('onboarding.start_title'),
                            // Back to the name page, whose answers stay, or
                            // from the "+" back to the circles.
                            onBack: context.canPop()
                                ? () => context.pop()
                                : null,
                          ),
                          // The steps and the question first, then any
                          // invitation waiting, then the two choices.
                          if (!addingCircle)
                            BlocBuilder<InboxCubit, InboxState>(
                              builder:
                                  (
                                    BuildContext context,
                                    InboxState inboxState,
                                  ) {
                                    // Nothing waiting: no gap either.
                                    if (inboxState.status !=
                                            InboxStatus.ready ||
                                        inboxState.inbox.needsReply == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.lg,
                                      ),
                                      // Capped to a short teaser so many
                                      // pending invitations don't push the
                                      // choice below out of reach; "عرض
                                      // الكل" opens the full notifications
                                      // list for the rest.
                                      child: PendingInvitesSection(
                                        cubit: context.read<InboxCubit>(),
                                        state: inboxState,
                                        maxItems: 2,
                                      ),
                                    );
                                  },
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          ChoiceCard(
                            icon: AppIcons.heart,
                            title: context.tr('onboarding.self_title'),
                            hint: context.tr('onboarding.self_hint'),
                            selected: state.careTarget == CareTarget.self,
                            onTap: () =>
                                cubit.selectCareTarget(CareTarget.self),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ChoiceCard(
                            icon: AppIcons.users,
                            title: context.tr('onboarding.other_title'),
                            hint: context.tr('onboarding.other_hint'),
                            selected: state.careTarget == CareTarget.other,
                            onTap: () =>
                                cubit.selectCareTarget(CareTarget.other),
                          ),
                          AnimatedSize(
                            duration: AppMotion.formScroll,
                            alignment: Alignment.topCenter,
                            child: state.careTarget == CareTarget.other
                                ? _PatientQuestion(state: state)
                                : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                        style: text.labelLarge?.copyWith(
                          color: context.tokens.textSecondary,
                        ),
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

/// The follow-up question, shown under "another person": a small header and
/// two choices, the same width as the cards above.
class _PatientQuestion extends StatelessWidget {
  const _PatientQuestion({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final OnboardingCubit cubit = context.read<OnboardingCubit>();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.inset),
            child: Text(
              context.tr('onboarding.patient_question'),
              style: text.titleSmall?.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.labelGap),
          ChoiceCard(
            icon: AppIcons.users,
            title: context.tr('onboarding.patient_uses_title'),
            hint: context.tr('onboarding.patient_uses_hint'),
            selected: state.patientUsesApp == true,
            onTap: () => cubit.selectPatientUsesApp(usesApp: true),
          ),
          const SizedBox(height: AppSpacing.md),
          ChoiceCard(
            icon: AppIcons.user,
            title: context.tr('onboarding.patient_no_title'),
            hint: context.tr('onboarding.patient_no_hint'),
            selected: state.patientUsesApp == false,
            onTap: () => cubit.selectPatientUsesApp(usesApp: false),
          ),
        ],
      ),
    );
  }
}
