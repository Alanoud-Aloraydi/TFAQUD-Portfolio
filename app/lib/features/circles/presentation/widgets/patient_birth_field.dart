import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/forms/picker_field.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/patient_pickers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The patient's birth date picker; required.
class PatientBirthField extends StatelessWidget {
  const PatientBirthField({
    required this.state,
    required this.cubit,
    super.key,
  });

  final CreateCircleState state;
  final CreateCircleCubit cubit;

  @override
  Widget build(BuildContext context) {
    final DateTime? date = state.birthDate;
    return PickerField(
      label: context.tr('circles.birth_date'),
      hint: context.tr('circles.birth_date_hint'),
      icon: AppIcons.calendar,
      value: date == null ? null : formatBirthDate(context, date),
      onTap: () => pickPatientBirthDate(context, cubit, date),
      errorText: state.showErrors && date == null
          ? context.tr('common.field_required')
          : null,
    );
  }
}
