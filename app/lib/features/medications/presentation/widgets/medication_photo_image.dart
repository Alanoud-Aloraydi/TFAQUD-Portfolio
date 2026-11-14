import 'dart:typed_data';

import 'package:app/core/media/photo_crop_page.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Displays the medication photo image UI.
class MedicationPhotoImage extends StatelessWidget {
  const MedicationPhotoImage({
    super.key,
    required this.bytes,
    required this.height,
    this.width = double.infinity,
    this.radius = AppRadius.m,
  });

  final Uint8List bytes;
  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => openPhotoViewer(context, bytes),
    child: Semantics(
      button: true,
      label: context.tr('photos.enlarge'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    ),
  );
}
