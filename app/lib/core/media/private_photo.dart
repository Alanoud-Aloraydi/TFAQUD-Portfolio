import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Defines the supported photo source values.
enum PhotoSource { camera, library, remove }

/// Displays the private photo UI.
class PrivatePhoto extends StatelessWidget {
  const PrivatePhoto({
    super.key,
    required this.path,
    required this.height,
    required this.fallback,
    this.width = double.infinity,
    this.radius = AppRadius.m,
    this.openViewer = true,
  });

  final String path;
  final double width;
  final double height;
  final double radius;
  final Widget fallback;
  final bool openViewer;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) => FutureBuilder<Uint8List?>(
        future: repository.load(path),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) return fallback;
          final image = ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.memory(
              bytes,
              width: width,
              height: height,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
          if (!openViewer) return image;
          return GestureDetector(
            onTap: () => openPhotoViewer(context, bytes),
            child: Semantics(
              button: true,
              label: context.tr('photos.enlarge'),
              child: image,
            ),
          );
        },
      ),
    );
  }
}

Future<PhotoSource?> showPhotoSourceSheet(
  BuildContext context, {
  required String title,
  bool canRemove = false,
}) => showGlassSheet<PhotoSource>(
  context,
  title: title,
  builder: (sheetContext) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: const Icon(CupertinoIcons.camera),
        title: Text(context.tr('photos.camera')),
        onTap: () => Navigator.pop(sheetContext, PhotoSource.camera),
      ),
      ListTile(
        leading: const Icon(CupertinoIcons.photo),
        title: Text(context.tr('photos.library')),
        onTap: () => Navigator.pop(sheetContext, PhotoSource.library),
      ),
      if (canRemove)
        ListTile(
          leading: const Icon(CupertinoIcons.trash),
          title: Text(context.tr('photos.remove')),
          onTap: () => Navigator.pop(sheetContext, PhotoSource.remove),
        ),
    ],
  ),
);

Future<Uint8List?> pickAndCropPhoto(
  BuildContext context,
  PhotoSource source, {
  bool circle = false,
  bool frontCamera = false,
}) async {
  XFile? selected;
  try {
    selected = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      preferredCameraDevice: frontCamera
          ? CameraDevice.front
          : CameraDevice.rear,
      maxWidth: 2048,
      imageQuality: 85,
    );
  } on PlatformException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('photos.access_failed'))),
      );
    }
    return null;
  }
  if (selected == null || !context.mounted) return null;
  final bytes = await selected.readAsBytes();
  if (!context.mounted) return null;
  return Navigator.of(context).push<Uint8List>(
    CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (_) => PhotoCropPage(bytes: bytes, circle: circle),
    ),
  );
}

/// Displays the photo crop page UI.
class PhotoCropPage extends StatefulWidget {
  const PhotoCropPage({super.key, required this.bytes, this.circle = false});

  final Uint8List bytes;
  final bool circle;

  @override
  State<PhotoCropPage> createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<PhotoCropPage> {
  final _frame = GlobalKey();
  final _transform = TransformationController();
  Size? _imageSize;
  Size? _frameSize;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    decodeImageFromList(widget.bytes).then((image) {
      if (mounted) {
        setState(
          () => _imageSize = Size(
            image.width.toDouble(),
            image.height.toDouble(),
          ),
        );
      }
      image.dispose();
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Size _cover(Size frame) {
    final factor = math.max(
      frame.width / _imageSize!.width,
      frame.height / _imageSize!.height,
    );
    return Size(_imageSize!.width * factor, _imageSize!.height * factor);
  }

  void _center(Size frame) {
    if (_frameSize == frame) return;
    final initial = _frameSize == null;
    _frameSize = frame;
    final fitted = _cover(frame);
    final matrix = Matrix4.translationValues(
      -(fitted.width - frame.width) / 2,
      -(fitted.height - frame.height) / 2,
      0,
    );
    if (initial) {
      _transform.value = matrix;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _transform.value = matrix;
      });
    }
  }

  Future<void> _use() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final frame = _frame.currentContext?.findRenderObject();
      if (frame is! RenderRepaintBoundary) return;
      final width = widget.circle ? 480.0 : 960.0;
      final image = await frame.toImage(pixelRatio: width / frame.size.width);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (mounted) Navigator.pop(context, data?.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground = AppSemanticColors.surfaceContent;
    return Scaffold(
      backgroundColor: AppSemanticColors.textPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    context.tr('common.cancel'),
                    style: TextStyle(color: foreground),
                  ),
                ),
                Expanded(
                  child: Text(
                    context.tr('photos.crop'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: foreground),
                  ),
                ),
                TextButton(
                  onPressed: _imageSize == null || _busy ? null : _use,
                  child: Text(
                    context.tr('photos.use'),
                    style: TextStyle(color: foreground),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: AspectRatio(
                    aspectRatio: widget.circle ? 1 : 4 / 3,
                    child: _imageSize == null
                        ? const Center(child: CupertinoActivityIndicator())
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final size = constraints.biggest;
                              _center(size);
                              final fitted = _cover(size);
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  RepaintBoundary(
                                    key: _frame,
                                    child: ClipRect(
                                      child: InteractiveViewer(
                                        transformationController: _transform,
                                        constrained: false,
                                        minScale: 1,
                                        maxScale: 5,
                                        child: Image.memory(
                                          widget.bytes,
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
                                        border: Border.all(color: foreground),
                                        borderRadius: widget.circle
                                            ? BorderRadius.circular(
                                                size.width / 2,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
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
                style: TextStyle(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void openPhotoViewer(BuildContext context, Uint8List bytes) {
  Navigator.of(context).push<void>(
    CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (viewerContext) => Scaffold(
        backgroundColor: AppSemanticColors.textPrimary,
        body: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
              ),
            ),
            PositionedDirectional(
              top: MediaQuery.paddingOf(viewerContext).top + AppSpacing.sm,
              end: AppSpacing.md,
              child: IconButton(
                onPressed: () => Navigator.pop(viewerContext),
                tooltip: viewerContext.tr('common.close'),
                icon: const Icon(
                  CupertinoIcons.xmark,
                  color: AppSemanticColors.surfaceContent,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
