import 'dart:typed_data';

import 'package:app/core/media/photo_viewer_page.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:flutter/material.dart';

/// Opens [bytes] over the whole app, tabs and top bar included: zoomable,
/// closed with the button at the top right or by dragging it away.
void openPhotoViewer(BuildContext context, Uint8List bytes) {
  Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      // The page under it shows through as the photo is dragged away.
      opaque: false,
      transitionDuration: AppMotion.contentEnter,
      reverseTransitionDuration: AppMotion.contentExit,
      pageBuilder: (_, _, _) => PhotoViewerPage(bytes: bytes),
      transitionsBuilder: (_, Animation<double> animation, _, Widget child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
