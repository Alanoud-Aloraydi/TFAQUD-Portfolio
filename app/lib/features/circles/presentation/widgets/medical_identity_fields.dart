import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/forms/picker_field.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_sheets.dart';
import 'package:app/features/circles/presentation/widgets/time_zone_names.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The birth date, the city, and the time zone. Every Saudi city has one
/// zone; any other city needs one picked here, because all the circle's
/// times follow it. The server's refusal of the birth date is under it.
List<Widget> medicalIdentityFields(
  BuildContext context, {
  required MedicalFileEditState state,
  required MedicalFileEditCubit cubit,
}) {
  final String requiredText = context.tr('common.field_required');
  final bool show = state.showErrors;
  final String? refused = isBirthDateError(state.errorKey)
      ? context.tr(state.errorKey!)
      : null;
  return <Widget>[
    FieldWithError.reveal(
      error: refused,
      child: PickerField(
        label: context.tr('circles.birth_date'),
        hint: context.tr('circles.birth_date_hint'),
        icon: ScheduleIcons.calendar,
        value: state.birthDate == null
            ? null
            : formatBirthDate(context, state.birthDate!),
        onTap: () => pickBirthDate(context, state, cubit),
        errorText:
            refused ?? (show && state.birthDate == null ? requiredText : null),
      ),
    ),
    const SizedBox(height: AppSpacing.lg),
    PickerField(
      label: context.tr('circles.city'),
      hint: context.tr('circles.patient_city_hint'),
      icon: ScheduleIcons.mapPin,
      value: state.city,
      onTap: () => pickCity(context, state, cubit),
      errorText: show && state.city == null ? requiredText : null,
    ),
    if (state.zoneEditable) ...<Widget>[
      const SizedBox(height: AppSpacing.lg),
      PickerField(
        label: context.tr('circles.time_zone'),
        hint: context.tr('circles.time_zone_sheet_title'),
        icon: ScheduleIcons.clock,
        value: state.timeZone == null ? null : timeZoneName(state.timeZone!),
        onTap: () => pickTimeZone(context, state, cubit),
        errorText: show && state.zoneMissing ? requiredText : null,
      ),
    ],
  ];
}
