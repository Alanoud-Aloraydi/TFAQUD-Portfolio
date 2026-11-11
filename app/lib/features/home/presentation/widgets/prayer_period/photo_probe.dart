import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tells its [builder] whether any of the medicines [planIds] of [circleId]
/// has a photo. The photos are looked up when the plans change, not on every
/// rebuild (the page rebuilds each minute).
class PhotoProbe extends StatefulWidget {
  const PhotoProbe({
    super.key,
    required this.circleId,
    required this.planIds,
    required this.builder,
  });

  final String circleId;
  final List<String> planIds;
  final Widget Function(BuildContext context, bool hasPhoto) builder;

  @override
  State<PhotoProbe> createState() => _PhotoProbeState();
}

class _PhotoProbeState extends State<PhotoProbe> {
  bool _hasPhoto = false;
  int _lookup = 0;

  @override
  void initState() {
    super.initState();
    _look();
  }

  @override
  void didUpdateWidget(PhotoProbe old) {
    super.didUpdateWidget(old);
    if (old.circleId != widget.circleId ||
        !listEquals(old.planIds, widget.planIds)) {
      _look();
    }
  }

  void _look() {
    final photos = RepositoryProvider.of<PrivatePhotoRepository>(context);
    final int lookup = ++_lookup;
    final String circleId = widget.circleId;
    Future.wait([
      for (final String id in widget.planIds)
        photos.load(ApiEndpoints.medicationPhoto(circleId, id)),
    ]).then((values) {
      final bool found = values.any((value) => value != null);
      if (mounted && lookup == _lookup && found != _hasPhoto) {
        setState(() => _hasPhoto = found);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _hasPhoto);
}
