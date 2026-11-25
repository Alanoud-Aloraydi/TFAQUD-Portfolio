import 'dart:typed_data';

import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/media/photo_crop_actions.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the photo editor holds until «حفظ», and the two things it does:
/// choose a new photo, and save the choice.
mixin PersonPhotoEditorActions on State<PersonPhotoEditor> {
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
