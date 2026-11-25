import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What the phone page asks: the number, and why it was refused.
class PhoneForm extends StatelessWidget {
  const PhoneForm({super.key, required this.controller, required this.state});

  final TextEditingController controller;
  final SignInState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StepHeader(
          title: context.tr('auth.phone_title'),
          subtitle: context.tr('auth.phone_subtitle'),
          // No back link when this is the first page:
          // the welcome was already shown on this install.
          onBack: context.canPop() ? () => context.pop() : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        PhoneField(
          controller: controller,
          showError: state.showPhoneError,
          onChanged: (String text) => context.read<SignInCubit>().phoneChanged(
            ArabicDigits.digitsOnly(text),
          ),
        ),
        if (state.errorKey != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          InlineError(messageKey: state.errorKey!),
        ],
      ],
    );
  }
}

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

/// A sign-in step's content: the [form] scrolls (and a drag hides the
/// keyboard), the [button] stays at the bottom.
class SignInStepColumn extends StatelessWidget {
  const SignInStepColumn({super.key, required this.form, required this.button});

  final Widget form;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: form,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        button,
      ],
    );
  }
}
