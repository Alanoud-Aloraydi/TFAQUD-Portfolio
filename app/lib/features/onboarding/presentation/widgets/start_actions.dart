import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// «متابعة» under the choice, and «تخطي الآن» in the first set-up.
class StartActions extends StatelessWidget {
  const StartActions({
    super.key,
    required this.state,
    required this.addingCircle,
  });

  final OnboardingState state;

  /// True when opened from the "+" to add another circle: no skip.
  final bool addingCircle;

  /// Opens the page that matches the complete choice in [state].
  void _continue(BuildContext context) {
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
    return Column(
      children: <Widget>[
        PillButton(
          label: context.tr('common.continue'),
          onPressed: state.canContinueStart ? () => _continue(context) : null,
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
  }
}
