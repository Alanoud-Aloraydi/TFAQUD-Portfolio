import 'dart:typed_data';

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// The picture under a light frame (round when [circle]), moved and zoomed
/// by [transform]; the cropped picture is taken from [frameKey].
class PhotoCropFrame extends StatelessWidget {
  const PhotoCropFrame({
    super.key,
    required this.bytes,
    required this.circle,
    required this.frameKey,
    required this.transform,
    required this.cover,
    required this.onFrameSize,
  });

  final Uint8List bytes;
  final bool circle;
  final GlobalKey frameKey;
  final TransformationController transform;

  /// The picture's size when it covers a frame of the given size.
  final Size Function(Size frame) cover;
  final ValueChanged<Size> onFrameSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        onFrameSize(size);
        final fitted = cover(size);
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              key: frameKey,
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: transform,
                  constrained: false,
                  minScale: 1,
                  maxScale: 5,
                  child: Image.memory(
                    bytes,
                    width: fitted.width,
                    height: fitted.height,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppSemanticColors.surfaceContent),
                  borderRadius: circle
                      ? BorderRadius.circular(size.width / 2)
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
