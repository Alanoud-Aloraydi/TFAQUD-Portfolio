import 'dart:typed_data';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/photo_crop_actions.dart';
import 'package:app/core/media/photo_crop_frame.dart';
import 'package:app/core/media/photo_viewer_drag.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

export 'package:app/core/media/photo_viewer.dart';

/// Full-screen page where the user moves and zooms [bytes] inside a square
/// (or [circle]) frame; pops with the cropped PNG.
class PhotoCropPage extends StatefulWidget {
  const PhotoCropPage({super.key, required this.bytes, this.circle = false});

  final Uint8List bytes;
  final bool circle;

  @override
  State<PhotoCropPage> createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<PhotoCropPage> with PhotoCropActions {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSemanticColors.textPrimary,
      body: SafeArea(
        child: Column(
          children: [
            PhotoCropTopBar(onUse: imageSize == null || busy ? null : use),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: AspectRatio(
                    aspectRatio: widget.circle ? 1 : 4 / 3,
                    child: imageSize == null
                        ? const Center(child: CupertinoActivityIndicator())
                        : PhotoCropFrame(
                            bytes: widget.bytes,
                            circle: widget.circle,
                            frameKey: frameKey,
                            transform: transform,
                            cover: cover,
                            onFrameSize: center,
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                context.tr('photos.crop_hint'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppSemanticColors.surfaceContent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pencil badge pinned to a photo's bottom corner, marking it editable.
/// Place inside a [Stack] (with `clipBehavior: Clip.none` over a circular
/// photo, since the badge sits partly outside the circle) alongside the
/// photo it edits.
class PhotoEditBadge extends StatelessWidget {
  const PhotoEditBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const PositionedDirectional(
      end: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppSemanticColors.surfaceContent,
          shape: CircleBorder(
            side: BorderSide(color: AppSemanticColors.borderSubtle),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xs),
          child: Icon(ActionIcons.pencil, size: 16),
        ),
      ),
    );
  }
}
