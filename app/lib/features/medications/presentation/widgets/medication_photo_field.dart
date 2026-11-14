import 'dart:typed_data';

import 'package:app/core/media/photo_edit_badge.dart';
import 'package:app/core/media/photo_source.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the medication photo field UI.
class MedicationPhotoField extends StatelessWidget {
  const MedicationPhotoField({
    super.key,
    required this.circleId,
    required this.planId,
    required this.photo,
    required this.removed,
    required this.onChanged,
  });

  final String circleId;
  final String? planId;
  final Uint8List? photo;
  final bool removed;
  final void Function(Uint8List? bytes, bool removed) onChanged;

  @override
  Widget build(BuildContext context) {
    final path = planId == null
        ? null
        : ApiEndpoints.medicationPhoto(circleId, planId!);
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            context.tr('photos.medication'),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        FutureBuilder<Uint8List?>(
          future: path == null ? null : repository.load(path),
          builder: (context, snapshot) {
            final bytes = removed ? null : photo ?? snapshot.data;
            return GestureDetector(
              onTap: () => _choose(context, bytes != null),
              child: Semantics(
                button: true,
                label: context.tr('photos.medication'),
                child: SizedBox(
                  height: 196,
                  width: double.infinity,
                  child: bytes == null
                      ? CustomPaint(
                          painter: MedicationPhotoBorder(),
                          child: const Center(
                            child: Icon(CupertinoIcons.camera, size: 30),
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                              child: Image.memory(bytes, fit: BoxFit.cover),
                            ),
                            const PhotoEditBadge(),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _choose(BuildContext context, bool hasPhoto) async {
    final source = await showPhotoSourceSheet(
      context,
      title: context.tr('photos.medication'),
      canRemove: hasPhoto,
    );
    if (source == null || !context.mounted) return;
    if (source == PhotoSource.remove) {
      onChanged(null, true);
      return;
    }
    final bytes = await pickAndCropPhoto(context, source);
    if (bytes != null) onChanged(bytes, false);
  }
}
