import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Where the patient's picture is kept. A patient with their own account
/// is one person with one photo: the account's, so the circle tab and the
/// profile stay in step.
String patientPhotoPath(String circleId, CircleOverview overview) =>
    overview.patientIsYou
    ? AccountEndpoints.accountPhoto
    : CircleEndpoints.patientPhoto(circleId);

/// The sheet that changes the patient's picture or avatar; [onSaved] reads
/// the circle again.
Future<void> editPatientPhoto(
  BuildContext context, {
  required String circleId,
  required CircleOverview overview,
  required VoidCallback onSaved,
}) => showPersonPhotoSheet(
  context,
  title: context.tr(
    'photos.patient_photo',
    args: <String>[overview.patientName],
  ),
  name: overview.patientName,
  photoPath: patientPhotoPath(circleId, overview),
  avatarPath: overview.patientIsYou
      ? AccountEndpoints.accountAvatar
      : CircleEndpoints.patientAvatar(circleId),
  avatarCode: overview.patientAvatarCode,
  onSaved: onSaved,
);
