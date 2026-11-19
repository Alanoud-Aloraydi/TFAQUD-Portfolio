import 'dart:typed_data';

import 'package:app/features/medications/presentation/widgets/medication_photo_builder.dart';
import 'package:flutter/material.dart';

/// A medicine's photo in a circle of [size], or [fallback] while it has
/// none: the round mark of a dose on «اليوم»'s cards.
class MedicationPhotoCircle extends StatelessWidget {
  const MedicationPhotoCircle({
    super.key,
    required this.circleId,
    required this.planId,
    required this.size,
    required this.fallback,
  });

  final String circleId;
  final String planId;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => MedicationPhotoBuilder(
    circleId: circleId,
    planId: planId,
    builder: (BuildContext context, Uint8List? bytes) => bytes == null
        ? fallback
        : ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
  );
}
