import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/choice_card.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The two choices of the start step, and under «أتابع رعاية شخص آخر» the
/// question whether that person uses the app.
class StartChoices extends StatelessWidget {
  const StartChoices({super.key, required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final OnboardingCubit cubit = context.read<OnboardingCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ChoiceCard(
          icon: CareIcons.heart,
          title: context.tr('onboarding.self_title'),
          hint: context.tr('onboarding.self_hint'),
          selected: state.careTarget == CareTarget.self,
          onTap: () => cubit.selectCareTarget(CareTarget.self),
        ),
        const SizedBox(height: AppSpacing.md),
        ChoiceCard(
          icon: PeopleIcons.users,
          title: context.tr('onboarding.other_title'),
          hint: context.tr('onboarding.other_hint'),
          selected: state.careTarget == CareTarget.other,
          onTap: () => cubit.selectCareTarget(CareTarget.other),
        ),
        AnimatedSize(
          duration: AppMotion.formScroll,
          alignment: Alignment.topCenter,
          child: state.careTarget == CareTarget.other
              ? PatientQuestion(state: state)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The follow-up question under «أتابع رعاية شخص آخر»: whether the
/// cared-for person uses the app, as two [ChoiceCard]s the width of the
/// cards above.
class PatientQuestion extends StatelessWidget {
  const PatientQuestion({super.key, required this.state});

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
            icon: PeopleIcons.users,
            title: context.tr('onboarding.patient_uses_title'),
            hint: context.tr('onboarding.patient_uses_hint'),
            selected: state.patientUsesApp == true,
            onTap: () => cubit.selectPatientUsesApp(usesApp: true),
          ),
          const SizedBox(height: AppSpacing.md),
          ChoiceCard(
            icon: PeopleIcons.user,
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
