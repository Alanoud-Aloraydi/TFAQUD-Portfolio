import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/core/widgets/pickers/city_sheet.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:flutter/material.dart';

/// Opens the birth date sheet and hands the chosen date to [cubit].
Future<void> pickPatientBirthDate(
  BuildContext context,
  CreateCircleCubit cubit,
  DateTime? current,
) async {
  final DateTime? picked = await showBirthDateSheet(context, selected: current);
  if (picked != null) cubit.birthDateChanged(picked);
}

/// Opens the city sheet and hands the chosen city to [cubit].
Future<void> pickPatientCity(
  BuildContext context,
  CreateCircleCubit cubit,
  String? current,
) async {
  final String? picked = await showCitySheet(
    context,
    selected: current,
    titleKey: 'circles.patient_city_sheet_title',
  );
  if (picked != null) cubit.cityChanged(picked);
}
