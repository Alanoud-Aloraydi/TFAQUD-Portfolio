import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/widgets/start_choices.dart';
import 'package:app/features/onboarding/presentation/widgets/start_invites.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The scrolling part of the start step: the header, any invitation waiting,
/// and the choices.
class StartContent extends StatelessWidget {
  const StartContent({
    super.key,
    required this.state,
    required this.addingCircle,
  });

  final OnboardingState state;

  /// True when opened from the "+" to add another circle.
  final bool addingCircle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            onBack: context.canPop() ? () => context.pop() : null,
          ),
          // The steps and the question first, then any
          // invitation waiting, then the two choices.
          if (!addingCircle) const StartInvites(),
          const SizedBox(height: AppSpacing.lg),
          StartChoices(state: state),
        ],
      ),
    );
  }
}
