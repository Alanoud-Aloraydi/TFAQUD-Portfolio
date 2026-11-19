import 'dart:typed_data';

import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/media/photo_crop_page.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_builder.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A medicine's photo in a circle of [size], or [fallback] while it has
/// none: the round mark of a dose on «اليوم»'s cards. A tap on the photo
/// opens it full screen, as everywhere else a medicine's photo shows.
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
        : GestureDetector(
            onTap: () => openPhotoViewer(context, bytes),
            child: Semantics(
              button: true,
              label: spoken(context.tr('photos.enlarge')),
              child: ClipOval(
                child: Image.memory(
                  bytes,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
  );
}
