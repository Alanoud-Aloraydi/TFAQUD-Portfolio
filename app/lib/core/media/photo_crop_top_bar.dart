import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «إلغاء», the page's title and «استخدام» over the dark crop page.
/// [onUse] is null until the picture is ready, and while it is cropped.
class PhotoCropTopBar extends StatelessWidget {
  const PhotoCropTopBar({super.key, required this.onUse});

  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final foreground = AppSemanticColors.surfaceContent;
    return Row(
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
          onPressed: onUse,
          child: Text(
            context.tr('photos.use'),
            style: TextStyle(color: foreground),
          ),
        ),
      ],
    );
  }
}
