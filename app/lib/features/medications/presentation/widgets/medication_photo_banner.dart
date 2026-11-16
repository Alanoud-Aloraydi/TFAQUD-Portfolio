import 'package:app/features/medications/presentation/widgets/medication_photo_builder.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_image.dart';
import 'package:flutter/material.dart';

/// The medicine's own photo above whatever follows it, and nothing at all
/// while there is no photo: no empty frame on a page that only reads.
class MedicationPhotoBanner extends StatelessWidget {
  const MedicationPhotoBanner({
    super.key,
    required this.circleId,
    required this.planId,
    required this.height,
    required this.bottomGap,
  });

  final String circleId;
  final String planId;
  final double height;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    return MedicationPhotoBuilder(
      circleId: circleId,
      planId: planId,
      builder: (context, bytes) => bytes == null
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.only(bottom: bottomGap),
              child: MedicationPhotoImage(bytes: bytes, height: height),
            ),
    );
  }
}
