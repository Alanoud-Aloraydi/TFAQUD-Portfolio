import 'dart:typed_data';

import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/media/photo_crop_actions.dart';
import 'package:app/core/media/photo_crop_page.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/medication_endpoints.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_effective_chips.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_border.dart';
import 'package:app/features/medications/presentation/widgets/medication_strength_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The medicine itself at the top of the form: its name, strength, form and
/// photo.
class MedicationFormMedicine extends StatelessWidget {
  const MedicationFormMedicine({super.key, required this.state});

  final MedicationFormState state;

  @override
  Widget build(BuildContext context) {
    return MedicationBasicFields(
      data: state.data,
      issue: state.issue,
      onChanged: state.changed,
      photoField: MedicationPhotoField(
        circleId: state.widget.circleId,
        planId: state.widget.plan?.id,
        photo: state.photo,
        removed: state.photoRemoved,
        onChanged: state.photoChanged,
      ),
    );
  }
}

/// The photo the person picked or removed, which is saved after the plan.
extension MedicationFormPhoto on MedicationFormState {
  void photoChanged(Uint8List? bytes, bool removed) => update(() {
    photo = bytes;
    photoRemoved = removed;
    photoDirty = true;
    dirty = true;
    errorKey = null;
  });
}

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
        : MedicationEndpoints.medicationPhoto(circleId, planId!);
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

/// The medicine's name, strength, form, and reason in one grouped section.
class MedicationBasicFields extends StatelessWidget {
  const MedicationBasicFields({
    super.key,
    required this.data,
    required this.onChanged,
    this.photoField,
    this.issue,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;
  final Widget? photoField;
  final MedicationFormIssue? issue;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      header: context.tr('medications.basic_details'),
      children: <Widget>[
        if (photoField != null)
          InsetBlock(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: photoField,
            ),
          ),
        InsetTextRow(
          label: context.tr('medications.name'),
          hint: context.tr('medications.name_hint'),
          controller: data.name,
          focusNode: data.nameFocus,
          errorText: issue?.field == MedicationFormField.name
              ? context.tr('common.field_required')
              : null,
          maxLength: 50,
          onChanged: (_) => onChanged(),
        ),
        MedicationStrengthRow(data: data, issue: issue, onChanged: onChanged),
        MedicationDosageFormChips(data: data, onChanged: onChanged),
        InsetTextRow(
          label: context.tr('medications.reason'),
          hint: context.tr('medications.optional'),
          controller: data.reason,
          maxLength: 100,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

/// What the form shows for the medicine's photo and what a tap on it does:
/// the picture with the pencil badge, or the dashed frame with a camera.
class MedicationPhotoTarget extends StatelessWidget {
  const MedicationPhotoTarget({
    super.key,
    required this.bytes,
    required this.onChanged,
  });

  final Uint8List? bytes;
  final void Function(Uint8List? bytes, bool removed) onChanged;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = this.bytes;
    return GestureDetector(
      onTap: () => chooseMedicationPhoto(
        context,
        hasPhoto: bytes != null,
        onChanged: onChanged,
      ),
      child: Semantics(
        button: true,
        label: spoken(context.tr('photos.medication')),
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
  }
}

/// Asks where the medicine's photo comes from, then crops what was picked.
/// Removing reports no bytes and the removal, so the form knows to delete
/// the one already saved.
Future<void> chooseMedicationPhoto(
  BuildContext context, {
  required bool hasPhoto,
  required void Function(Uint8List? bytes, bool removed) onChanged,
}) async {
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
