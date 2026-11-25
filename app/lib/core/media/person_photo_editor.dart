import 'dart:typed_data';

import 'package:app/core/media/avatar_codes.dart';
import 'package:app/core/media/person_photo_preview.dart';
import 'package:app/core/media/photo_crop_actions.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The sheet body: preview, avatar choices and save. Nothing is sent until
/// the save button; a failed save keeps the sheet open with a message.
class PersonPhotoEditor extends StatefulWidget {
  const PersonPhotoEditor({
    super.key,
    required this.title,
    required this.name,
    required this.photoPath,
    required this.avatarPath,
    required this.avatarCode,
    required this.frontCamera,
    required this.onSaved,
  });

  final String title;
  final String name;
  final String photoPath;
  final String avatarPath;
  final String? avatarCode;
  final bool frontCamera;
  final VoidCallback? onSaved;

  @override
  State<PersonPhotoEditor> createState() => _PersonPhotoEditorState();
}

class _PersonPhotoEditorState extends State<PersonPhotoEditor> {
  @override
  void initState() {
    super.initState();
    code = widget.avatarCode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PhotoVisibilityNote(frontCamera: widget.frontCamera),
        const SizedBox(height: AppSpacing.md),
        PersonPhotoPreview(
          name: widget.name,
          photoPath: widget.photoPath,
          avatarCode: widget.avatarCode,
          selected: selected,
          removed: removed,
          code: code,
          onTap: choose,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AvatarChoicesLabel(),
        const SizedBox(height: AppSpacing.md),
        AvatarChoiceGrid(
          chosen: selected == null ? code : null,
          onChosen: (String chosen) => setState(() {
            code = chosen;
            selected = null;
            removed = false;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: saving ? null : save,
          style: FilledButton.styleFrom(
            backgroundColor: AppSemanticColors.textPrimary,
            foregroundColor: AppSemanticColors.surfaceContent,
          ),
          child: Text(context.tr('account.save')),
        ),
      ],
    );
  }

  Uint8List? selected;
  String? code;
  bool removed = false;
  bool saving = false;

  Future<void> choose() async {
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    Uint8List? existing;
    try {
      existing = removed ? null : await repository.load(widget.photoPath);
    } catch (_) {
      // The picker remains available while a photo read cannot complete.
    }
    if (!mounted) return;
    final choice = await showPhotoSourceSheet(
      context,
      title: widget.title,
      canRemove: existing != null || selected != null || code != null,
    );
    if (choice == null || !mounted) return;
    if (choice == PhotoSource.remove) {
      setState(() {
        removed = true;
        selected = null;
        code = null;
      });
      return;
    }
    final bytes = await pickAndCropPhoto(
      context,
      choice,
      circle: true,
      frontCamera: widget.frontCamera,
    );
    if (bytes == null || !mounted) return;
    setState(() {
      selected = bytes;
      code = null;
      removed = false;
    });
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    try {
      if (selected != null) {
        await repository.save(widget.photoPath, selected!);
      } else if (code != null && code != widget.avatarCode) {
        await repository.chooseAvatar(widget.avatarPath, code!);
      } else if (removed) {
        await repository.remove(widget.avatarPath);
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        AppToast.show(context, 'photos.save_failed', kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

String personPhotoPath(String circleId, String? accountId) => accountId == null
    ? CircleEndpoints.patientPhoto(circleId)
    : CircleEndpoints.memberPhoto(circleId, accountId);

/// «اختر شخصية» and a line to the far edge, above the avatars.
class AvatarChoicesLabel extends StatelessWidget {
  const AvatarChoicesLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.tr('photos.choose_character'),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// The avatars to choose from, four a row; [chosen] has a ring.
class AvatarChoiceGrid extends StatelessWidget {
  const AvatarChoiceGrid({
    super.key,
    required this.chosen,
    required this.onChosen,
  });

  final String? chosen;
  final ValueChanged<String> onChosen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: avatarCodes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 72,
      ),
      itemBuilder: (context, index) {
        final code = avatarCodes[index];
        // A square in the middle of the cell, so the picture stays a
        // circle whatever the cell's width is.
        return Center(
          child: GestureDetector(
            onTap: () => onChosen(code),
            child: AnimatedContainer(
              duration: AppMotion.fieldFeedback,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: chosen == code
                    ? Border.all(
                        color: AppSemanticColors.actionPrimary,
                        width: 2,
                      )
                    : null,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/avatars/$code.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Who sees the photo: the account's own photo ([frontCamera]) or a
/// patient's.
class PhotoVisibilityNote extends StatelessWidget {
  const PhotoVisibilityNote({super.key, required this.frontCamera});

  final bool frontCamera;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(
        frontCamera ? 'photos.account_visibility' : 'photos.patient_visibility',
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
