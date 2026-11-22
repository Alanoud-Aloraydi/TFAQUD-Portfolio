import 'dart:typed_data';

import 'package:app/core/media/photo_viewer_drag.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A photo full screen, zoomable, closed with the button at the top right
/// or by dragging it away ([PhotoViewerDrag]). Zoomed in, a drag moves
/// around the photo instead.
class PhotoViewerPage extends StatefulWidget {
  const PhotoViewerPage({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage>
    with SingleTickerProviderStateMixin, PhotoViewerDrag<PhotoViewerPage> {
  final TransformationController _zoom = TransformationController();

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    return Scaffold(
      backgroundColor: AppSemanticColors.textPrimary.withValues(alpha: fade),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragUpdate: zoomed ? null : dragBy,
              onVerticalDragEnd: zoomed ? null : release,
              child: Transform.translate(
                offset: Offset(0, drag),
                child: InteractiveViewer(
                  transformationController: _zoom,
                  // Moving around is for a zoomed photo; unzoomed, a drag
                  // takes it away.
                  panEnabled: zoomed,
                  maxScale: 5,
                  child: Center(
                    child: Image.memory(widget.bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          // Start is the right in Arabic.
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
            start: AppSpacing.md,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: context.tr('common.close'),
              icon: const Icon(
                CupertinoIcons.xmark,
                color: AppSemanticColors.surfaceContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
