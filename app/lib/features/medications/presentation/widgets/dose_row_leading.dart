import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_builder.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_image.dart';
import 'package:flutter/material.dart';

/// The start of a dose row: the medicine's photo when it has one, otherwise
/// the shared medicine icon. Both are the same size, so the rows line up.
class DoseRowLeading extends StatelessWidget {
  const DoseRowLeading({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) {
    const Widget icon = TodayTaskKindIcon(
      icon: CareVisuals.medicationIcon,
      background: CareVisuals.medicationTile,
    );
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
