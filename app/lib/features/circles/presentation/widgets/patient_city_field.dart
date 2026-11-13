import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/forms/picker_field.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/patient_pickers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The patient's city picker; required. It sets the time of the
/// reminders and the prayer times.
class PatientCityField extends StatelessWidget {
  const PatientCityField({required this.state, required this.cubit, super.key});

  final CreateCircleState state;
  final CreateCircleCubit cubit;

  @override
  Widget build(BuildContext context) {
    return PickerField(
      label: context.tr('circles.city'),
      hint: context.tr('circles.patient_city_hint'),
      icon: AppIcons.mapPin,
      value: state.city,
      onTap: () => pickPatientCity(context, cubit, state.city),
      errorText: state.showErrors && state.city == null
          ? context.tr('common.field_required')
          : null,
    );
  }
}
