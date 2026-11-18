import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_edit_badge.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/network/circle_endpoints.dart';

/// The patient's picture on the circle card, with the pencil badge and the
/// sheet that changes it for whoever is allowed to. A patient with their own
/// account is one person with one photo: it is edited through the account
/// endpoint, so the circle tab and the profile stay in step.
class PatientPhotoButton extends StatelessWidget {
  const PatientPhotoButton({
    super.key,
    required this.circleId,
    required this.overview,
  });

  final String circleId;
  final CircleOverview overview;

  String get _photoPath => overview.patientIsYou
      ? AccountEndpoints.accountPhoto
      : CircleEndpoints.patientPhoto(circleId);

  @override
  Widget build(BuildContext context) {
    final String title = context.tr(
      'photos.patient_photo',
      args: <String>[overview.patientName],
    );
    return Semantics(
      button: overview.canEditPatientPhoto,
      label: spoken(title),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: overview.canEditPatientPhoto
            ? () => showPersonPhotoSheet(
                context,
                title: title,
                name: overview.patientName,
                photoPath: _photoPath,
                avatarPath: overview.patientIsYou
                    ? AccountEndpoints.accountAvatar
                    : CircleEndpoints.patientAvatar(circleId),
                avatarCode: overview.patientAvatarCode,
                onSaved: context.read<CircleOverviewCubit>().load,
              )
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            PersonPhoto(
              name: overview.patientName,
              photoPath: _photoPath,
              avatarCode: overview.patientAvatarCode,
              size: AppSizes.avatarLarge,
            ),
            if (overview.canEditPatientPhoto) const PhotoEditBadge(),
          ],
        ),
      ),
    );
  }
}
