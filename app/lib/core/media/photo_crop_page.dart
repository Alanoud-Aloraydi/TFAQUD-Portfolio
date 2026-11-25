import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/photo_viewer.dart';
import 'package:app/core/media/photo_viewer_drag.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

class _PhotoCropPageState extends State<PhotoCropPage> {
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

  final frameKey = GlobalKey();
  final transform = TransformationController();
  Size? imageSize;
  Size? frameSize;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    decodeImageFromList(widget.bytes).then((image) {
      if (mounted) {
        setState(
          () =>
              imageSize = Size(image.width.toDouble(), image.height.toDouble()),
        );
      }
      image.dispose();
    });
  }

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  Size cover(Size frame) {
    final factor = math.max(
      frame.width / imageSize!.width,
      frame.height / imageSize!.height,
    );
    return Size(imageSize!.width * factor, imageSize!.height * factor);
  }

  void center(Size frame) {
    if (frameSize == frame) return;
    final initial = frameSize == null;
    frameSize = frame;
    final fitted = cover(frame);
    final matrix = Matrix4.translationValues(
      -(fitted.width - frame.width) / 2,
      -(fitted.height - frame.height) / 2,
      0,
    );
    if (initial) {
      transform.value = matrix;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) transform.value = matrix;
      });
    }
  }

  Future<void> use() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final frame = frameKey.currentContext?.findRenderObject();
      if (frame is! RenderRepaintBoundary) return;
      final png = await cropFramePng(frame, widget.circle ? 480.0 : 960.0);
      if (png == null) return;
      if (mounted) Navigator.pop(context, png);
    } finally {
      if (mounted) setState(() => busy = false);
    }
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

/// What [frame] shows, as a PNG [width] pixels wide; null when its pixels
/// cannot be read.
Future<Uint8List?> cropFramePng(
  RenderRepaintBoundary frame,
  double width,
) async {
  final image = await frame.toImage(pixelRatio: width / frame.size.width);
  RgbaPixels? pixels;
  try {
    // 8-bit sRGB pixels, then the app's own PNG: the engine's PNG of a
    // wide-colour iPhone image may not be one the server accepts.
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (data != null) {
      pixels = (
        rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        width: image.width,
        height: image.height,
      );
    }
  } finally {
    image.dispose();
  }
  if (pixels == null) return null;
  return compute(encodeRgbaPng, pixels);
}

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
