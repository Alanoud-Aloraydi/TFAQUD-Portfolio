import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/forms/birth_date_city_fields.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The patient's birth date and city, asked only of an account that has not
/// saved them yet: onboarding asks for both now.
class CircleBasicsFields extends StatelessWidget {
  const CircleBasicsFields({
    super.key,
    required this.cubit,
    required this.state,
    required this.topGap,
  });

  final CreateCircleCubit cubit;
  final CreateCircleState state;
  final double topGap;

  /// Whether the page shows the fields for [state].
  static bool shown(CreateCircleState state) =>
      state.asksBasics && !state.waitingForAccount;

  @override
  Widget build(BuildContext context) {
    if (!shown(state)) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: BirthDateCityFields(
        birthDate: state.birthDate,
        city: state.city,
        onBirthDate: cubit.birthDateChanged,
        onCity: cubit.cityChanged,
        showErrors: state.showErrors,
        birthDateError: isBirthDateError(state.errorKey)
            ? context.tr(state.errorKey!)
            : null,
      ),
    );
  }
}

/// Why the last try to create the circle was refused, as a toast. A refusal
/// of the birth date is shown under its field while the page asks for it
/// ([CircleBasicsFields]).
class CircleBasicsError extends StatelessWidget {
  const CircleBasicsError({super.key, required this.state});

  final CreateCircleState state;

  @override
  Widget build(BuildContext context) {
    final String? key = state.errorKey;
    final bool underField =
        isBirthDateError(key) && CircleBasicsFields.shown(state);
    return ErrorToast(
      errorKey: underField ? null : key,
      child: const SizedBox.shrink(),
    );
  }
}
