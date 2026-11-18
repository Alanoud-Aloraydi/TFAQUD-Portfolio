export 'package:app/core/media/photo_source_sheet.dart';
export 'package:app/core/media/pick_and_crop_photo.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/media/photo_viewer.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A photo behind the signed-in session, loaded through
/// [PrivatePhotoRepository] (bearer token, in-memory cache cleared on
/// sign-out) and never written to disk. Shows [fallback] while it loads, when
/// there is none, or when the read fails; a tap opens it full screen when
/// [openViewer] is true.
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
      listenable: repository.changes,
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
              label: spoken(context.tr('photos.enlarge')),
              child: image,
            ),
          );
        },
      ),
    );
  }
}
