import 'dart:math' as math;

import 'package:app/core/media/crop_frame_png.dart';
import 'package:app/core/media/photo_crop_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The crop page's picture and frame: the picture's size once decoded, the
/// move and zoom inside the frame, and cropping it to a PNG.
mixin PhotoCropActions on State<PhotoCropPage> {
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
