import 'dart:typed_data';

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Opens [bytes] full screen, zoomable.
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
