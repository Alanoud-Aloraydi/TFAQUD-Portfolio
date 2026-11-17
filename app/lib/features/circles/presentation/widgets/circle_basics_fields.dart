import 'package:app/core/widgets/forms/birth_date_city_fields.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
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

  @override
  Widget build(BuildContext context) {
    if (!state.asksBasics || state.waitingForAccount) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: BirthDateCityFields(
        birthDate: state.birthDate,
        city: state.city,
        onBirthDate: cubit.birthDateChanged,
        onCity: cubit.cityChanged,
        showErrors: state.showErrors,
      ),
    );
  }
}
