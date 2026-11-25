import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The drag that takes a photo away (PhotoViewerPage): the photo follows
/// the finger up or down, and let go far or fast enough it closes the
/// page, as in the phone's own photos; let go near, it goes back.
mixin PhotoViewerDrag<T extends StatefulWidget> on State<T>, TickerProvider {
  /// How far a drag closes it, and how fast a flick does.
  static const double _closeAt = 120;
  static const double _flick = 800;

  /// How far the photo is from its place, up or down.
  double drag = 0;
  double _from = 0;

  late final AnimationController _back;

  @override
  void initState() {
    super.initState();
    _back = AnimationController(vsync: this, duration: AppMotion.contentExit)
      ..addListener(() => setState(() => drag = _from * (1 - _back.value)));
  }

  /// How much of the dark stays around it: less the farther it goes.
  double get fade => (1 - drag.abs() / (_closeAt * 3)).clamp(0.3, 1.0);

  void dragBy(DragUpdateDetails details) =>
      setState(() => drag += details.delta.dy);

  void release(DragEndDetails details) {
    final double speed = details.primaryVelocity ?? 0;
    if (drag.abs() > _closeAt || speed.abs() > _flick) {
      Navigator.pop(context);
      return;
    }
    _from = drag;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => drag = 0);
    } else {
      _back.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }
}

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
