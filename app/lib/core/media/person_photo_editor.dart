import 'package:app/core/media/avatar_choice_grid.dart';
import 'package:app/core/media/avatar_choices_label.dart';
import 'package:app/core/media/person_photo_editor_actions.dart';
import 'package:app/core/media/person_photo_preview.dart';
import 'package:app/core/media/photo_visibility_note.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

export 'person_photo_path.dart';

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

class _PersonPhotoEditorState extends State<PersonPhotoEditor>
    with PersonPhotoEditorActions {
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
}
