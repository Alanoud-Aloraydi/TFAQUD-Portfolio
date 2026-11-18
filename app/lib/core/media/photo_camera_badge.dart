import 'package:app/core/widgets/navigation/glass.dart';
import 'package:flutter/cupertino.dart';

/// The round glass camera at the corner of the photo being edited.
class PhotoCameraBadge extends StatelessWidget {
  const PhotoCameraBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassSurface(
      borderRadius: BorderRadius.all(Radius.circular(17)),
      child: SizedBox.square(
        dimension: 34,
        child: Icon(CupertinoIcons.camera, size: 17),
      ),
    );
  }
}
