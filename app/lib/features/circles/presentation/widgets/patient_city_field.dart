import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/forms/picker_field.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/core/widgets/pickers/city_sheet.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/edit_patient_photo.dart';
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
      icon: ScheduleIcons.mapPin,
      value: state.city,
      onTap: () => pickPatientCity(context, cubit, state.city),
      errorText: state.showErrors && state.city == null
          ? context.tr('common.field_required')
          : null,
    );
  }
}

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

/// The patient's picture on the circle card. It is changed with the name,
/// from the pen beside the name, by whoever may.
class PatientCardPhoto extends StatelessWidget {
  const PatientCardPhoto({
    super.key,
    required this.circleId,
    required this.overview,
  });

  final String circleId;
  final CircleOverview overview;

  @override
  Widget build(BuildContext context) => PersonPhoto(
    name: overview.patientName,
    photoPath: patientPhotoPath(circleId, overview),
    avatarCode: overview.patientAvatarCode,
    size: AppSizes.avatarLarge,
  );
}
