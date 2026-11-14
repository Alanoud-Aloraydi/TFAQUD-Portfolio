import 'dart:typed_data';

import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the medication photo builder UI.
class MedicationPhotoBuilder extends StatelessWidget {
  const MedicationPhotoBuilder({
    super.key,
    required this.circleId,
    required this.planId,
    required this.builder,
  });

  final String circleId;
  final String planId;
  final Widget Function(BuildContext context, Uint8List? bytes) builder;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    final path = ApiEndpoints.medicationPhoto(circleId, planId);
    return ListenableBuilder(
      listenable: repository.changes,
      builder: (context, _) => FutureBuilder<Uint8List?>(
        future: repository.load(path),
        builder: (context, snapshot) => builder(context, snapshot.data),
      ),
    );
  }
}
