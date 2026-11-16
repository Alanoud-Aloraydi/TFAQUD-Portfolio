import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/choice_card.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The follow-up question under «أتابع رعاية شخص آخر»: whether the
/// cared-for person uses the app, as two [ChoiceCard]s the width of the
/// cards above.
class PatientQuestion extends StatelessWidget {
  const PatientQuestion({required this.state});

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
