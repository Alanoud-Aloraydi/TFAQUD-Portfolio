import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The three name fields of the name step: their texts, and the display name
/// that follows the first name until the person edits it.
mixin ProfileStepNames<T extends StatefulWidget> on State<T> {
  final TextEditingController first = TextEditingController();
  final TextEditingController last = TextEditingController();
  final TextEditingController display = TextEditingController();

  /// Until the user edits the display name, it follows the first name.
  bool _displayEdited = false;

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    display.dispose();
    super.dispose();
  }

  void onFirstNameChanged(String value) {
    final OnboardingCubit cubit = context.read<OnboardingCubit>();
    cubit.firstNameChanged(value);
    if (!_displayEdited) {
      // Text set by code is not cut by the field's limit, so it is cut here,
      // in code points as the server counts, never inside an emoji.
      final String shown = limitCodePoints(value, NameLimits.displayName);
      display.text = shown;
      cubit.displayNameChanged(shown);
    }
  }

  void onDisplayNameChanged(String value) {
    _displayEdited = true;
    context.read<OnboardingCubit>().displayNameChanged(value);
  }
}
