import 'package:app/core/media/private_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// A medicine's photo, the way the patient recognises it; while it has
/// none, the medicines' own look ([CareVisuals]): a pill on green.
class MedicinePhoto extends StatelessWidget {
  const MedicinePhoto({
    super.key,
    required this.circleId,
    required this.planId,
    required this.height,
    this.width = double.infinity,
    this.radius = SimplifiedStyle.radius,
    this.iconSize = 44,
  });

  final String circleId;
  final String planId;
  final double height;
  final double width;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return PrivatePhoto(
      path: ApiEndpoints.medicationPhoto(circleId, planId),
      height: height,
      width: width,
      radius: radius,
      openViewer: false,
      fallback: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: CareVisuals.medicationTile,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(
          CareVisuals.medicationIcon,
          size: iconSize,
          color: AppSemanticColors.onSettingsTile,
        ),
      ),
    );
  }
}
