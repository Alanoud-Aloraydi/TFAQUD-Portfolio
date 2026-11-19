import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/forms/picker_field.dart';
import 'package:app/core/widgets/pickers/birth_date_note.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/patient_pickers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The patient's birth date picker; required. The server's refusal of the
/// date is shown under it.
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
    final String? refused = isBirthDateError(state.errorKey)
        ? context.tr(state.errorKey!)
        : null;
    return FieldWithError.reveal(
      error: refused,
      child: PickerField(
        label: context.tr('circles.birth_date'),
        hint: context.tr('circles.birth_date_hint'),
        icon: ScheduleIcons.calendar,
        value: date == null ? null : formatBirthDate(context, date),
        note: birthDateNote(context, date),
        onTap: () => pickPatientBirthDate(context, cubit, date),
        errorText:
            refused ??
            (state.showErrors && date == null
                ? context.tr('common.field_required')
                : null),
      ),
    );
  }
}
