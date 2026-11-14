import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_builder.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_image.dart';
import 'package:flutter/material.dart';

/// The start of a medicine's plan or record card: its photo, or a pill when
/// it has none, at the size every kind of card uses for its leading visual.
class MedicationLeading extends StatelessWidget {
  const MedicationLeading({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) => MedicationPhotoBuilder(
    circleId: circleId,
    planId: planId,
    builder: (BuildContext context, bytes) => bytes == null
        ? Container(
            width: AppItemCard.leading,
            height: AppItemCard.leading,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppSemanticColors.surfaceContent,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: const Icon(
              TafaqodPhosphorIcons.pill,
              color: AppSemanticColors.textSupporting,
            ),
          )
        : MedicationPhotoImage(
            bytes: bytes,
            width: AppItemCard.leading,
            height: AppItemCard.leading,
          ),
  );
}
