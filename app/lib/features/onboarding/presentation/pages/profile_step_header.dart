import 'package:app/core/widgets/layout/step_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The header of the name step: step 1 of 2, and «رجوع» to the phone number.
class ProfileStepHeader extends StatelessWidget {
  const ProfileStepHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return StepHeader(
      // The first account set-up: the name, then where
      // to start.
      step: 1,
      totalSteps: 2,
      title: context.tr('onboarding.name_title'),
      subtitle: context.tr('onboarding.name_subtitle'),
      // Back to the phone number, signed out.
      onBack: onBack,
    );
  }
}
