import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/choice_card.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/widgets/patient_question.dart';
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
