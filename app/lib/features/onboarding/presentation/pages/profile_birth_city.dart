import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/feedback/error_toast.dart';
import 'package:app/core/widgets/forms/birth_date_city_fields.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The birth date and the city of the name step. A refused birth date is
/// said under it; any other refusal of the save is a toast.
class ProfileBirthCity extends StatelessWidget {
  const ProfileBirthCity({super.key, required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final OnboardingCubit cubit = context.read<OnboardingCubit>();
    final String? birthError = isBirthDateError(state.errorKey)
        ? context.tr(state.errorKey!)
        : null;
    return ErrorToast(
      errorKey: birthError == null ? state.errorKey : null,
      child: BirthDateCityFields(
        birthDate: state.birthDate,
        city: state.city,
        onBirthDate: cubit.birthDateChanged,
        onCity: cubit.cityChanged,
        showErrors: state.showErrors,
        birthDateError: birthError,
      ),
    );
  }
}
