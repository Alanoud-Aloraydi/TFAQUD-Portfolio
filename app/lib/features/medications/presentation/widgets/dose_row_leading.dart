import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_field.dart';
import 'package:flutter/material.dart';

/// The start of a dose row: the medicine's photo when it has one and the
/// period shows photos, otherwise the shared medicine icon.
class DoseRowLeading extends StatelessWidget {
  const DoseRowLeading({
    super.key,
    required this.circleId,
    required this.planId,
    required this.showPhoto,
  });

  final String circleId;
  final String planId;
  final bool showPhoto;

  @override
  Widget build(BuildContext context) {
    const Widget icon = TodayTaskKindIcon(
      icon: CareVisuals.medicationIcon,
      background: CareVisuals.medicationTile,
    );
    if (!showPhoto) return icon;
    return MedicationPhotoBuilder(
      circleId: circleId,
      planId: planId,
      builder: (BuildContext context, bytes) => bytes == null
          ? icon
          : MedicationPhotoImage(
              bytes: bytes,
              width: AppItemCard.leading,
              height: AppItemCard.leading,
            ),
    );
  }
}
