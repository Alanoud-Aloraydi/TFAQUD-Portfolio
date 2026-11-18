import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The page around a sign-in step (the phone number, the code): the safe
/// area and the margins.
class SignInStepFrame extends StatelessWidget {
  const SignInStepFrame({super.key, required this.child});

  final Widget child;

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
          child: child,
        ),
      ),
    );
  }
}
