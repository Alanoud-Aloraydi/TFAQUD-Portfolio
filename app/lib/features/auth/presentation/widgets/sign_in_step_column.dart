import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

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
