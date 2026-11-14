import 'dart:typed_data';

import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_source.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
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
  Uint8List? _selected;
  String? _code;
  bool _removed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code = widget.avatarCode;
  }

  Future<void> _choose() async {
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    Uint8List? existing;
    try {
      existing = _removed ? null : await repository.load(widget.photoPath);
    } catch (_) {
      // The picker remains available while a photo read cannot complete.
    }
    if (!mounted) return;
    final choice = await showPhotoSourceSheet(
      context,
      title: widget.title,
      canRemove: existing != null || _selected != null || _code != null,
    );
    if (choice == null || !mounted) return;
    if (choice == PhotoSource.remove) {
      setState(() {
        _removed = true;
        _selected = null;
        _code = null;
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
      _selected = bytes;
      _code = null;
      _removed = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    try {
      if (_selected != null) {
        await repository.save(widget.photoPath, _selected!);
      } else if (_code != null && _code != widget.avatarCode) {
        await repository.chooseAvatar(widget.avatarPath, _code!);
      } else if (_removed) {
        await repository.remove(widget.avatarPath);
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        AppToast.show(context, 'photos.save_failed', kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _selected != null
        ? ClipOval(
            child: Image.memory(
              _selected!,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          )
        : _removed
        ? _initial(context)
        : PersonPhoto(
            name: widget.name,
            photoPath: _code == widget.avatarCode ? widget.photoPath : '',
            avatarCode: _code,
            size: 96,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(
            widget.frontCamera
                ? 'photos.account_visibility'
                : 'photos.patient_visibility',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: GestureDetector(
            onTap: _choose,
            child: SizedBox.square(
              dimension: 96,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppSemanticColors.borderSubtle),
                    ),
                    child: preview,
                  ),
                  const PositionedDirectional(
                    bottom: 0,
                    end: 0,
                    child: GlassSurface(
                      borderRadius: BorderRadius.all(Radius.circular(17)),
                      child: SizedBox.square(
                        dimension: 34,
                        child: Icon(CupertinoIcons.camera, size: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text(
              context.tr('photos.choose_character'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
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
                onTap: () => setState(() {
                  _code = code;
                  _selected = null;
                  _removed = false;
                }),
                child: AnimatedContainer(
                  duration: AppMotion.fieldFeedback,
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: _code == code && _selected == null
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
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppSemanticColors.textPrimary,
            foregroundColor: AppSemanticColors.surfaceContent,
          ),
          child: Text(context.tr('account.save')),
        ),
      ],
    );
  }

  Widget _initial(BuildContext context) => CircleAvatar(
    radius: 48,
    backgroundColor: AppSemanticColors.selectedSurface,
    child: Text(widget.name.isEmpty ? '؟' : widget.name.characters.first),
  );
}

String personPhotoPath(String circleId, String? accountId) => accountId == null
    ? ApiEndpoints.patientPhoto(circleId)
    : ApiEndpoints.memberPhoto(circleId, accountId);
