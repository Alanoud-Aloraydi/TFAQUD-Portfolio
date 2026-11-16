import 'dart:typed_data';

import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_target.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «صورة الدواء» in the form: the photo saved for the medicine, the one
/// just picked, or the dashed frame that asks for one.
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
          builder: (context, snapshot) => MedicationPhotoTarget(
            bytes: removed ? null : photo ?? snapshot.data,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
