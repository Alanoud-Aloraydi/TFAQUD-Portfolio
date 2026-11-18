import 'package:app/core/utils/birth_date_rules.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/core/widgets/pickers/city_sheet.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/time_zone_sheet.dart';
import 'package:flutter/material.dart';

/// The three sheets the medical file picks its answers from. Each keeps the
/// saved answer selected, and leaves it alone when the sheet is dismissed.
Future<void> pickBirthDate(
  BuildContext context,
  MedicalFileEditState state,
  MedicalFileEditCubit cubit,
) async {
  // A patient with an account holds it, so is 15 or older.
  final DateTime? picked = await showBirthDateSheet(
    context,
    selected: state.birthDate,
    youngestAge: (state.file?.patient.hasAccount ?? false)
        ? BirthDateRules.youngestAccountAge
        : 0,
  );
  if (picked != null) cubit.birthDateChanged(picked);
}

Future<void> pickCity(
  BuildContext context,
  MedicalFileEditState state,
  MedicalFileEditCubit cubit,
) async {
  final String? picked = await showCitySheet(
    context,
    selected: state.city,
    titleKey: 'circles.patient_city_sheet_title',
  );
  if (picked != null) cubit.cityChanged(picked);
}

Future<void> pickTimeZone(
  BuildContext context,
  MedicalFileEditState state,
  MedicalFileEditCubit cubit,
) async {
  final String? picked = await showTimeZoneSheet(
    context,
    selected: state.timeZone,
  );
  if (picked != null) cubit.timeZoneChanged(picked);
}
