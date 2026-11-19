import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/edit_patient_photo.dart';
import 'package:flutter/material.dart';

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
