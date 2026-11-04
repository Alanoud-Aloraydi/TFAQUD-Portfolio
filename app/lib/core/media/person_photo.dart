import 'dart:typed_data';

import 'package:app/core/media/private_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const avatarCodes = <String>[
  'w1_1',
  'w1_3',
  'w6_1',
  'w6_3',
  'm1_1',
  'm1_3',
  'm2_1',
  'm2_3',
  'm6_1',
  'm6_3',
  'w7_1',
  'w7_3',
];

/// Displays the person photo UI.
class PersonPhoto extends StatelessWidget {
  const PersonPhoto({
    super.key,
    required this.name,
    required this.photoPath,
    required this.size,
    this.avatarCode,
  });

  final String name;
  final String photoPath;
  final String? avatarCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final code = avatarCode;
    final fallback = ClipOval(
      child: code != null && avatarCodes.contains(code)
          ? Image.asset(
              'assets/avatars/$code.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
          : Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              color: AppSemanticColors.selectedSurface,
              child: Text(
                name.trim().isEmpty ? '؟' : name.trim().characters.first,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
    );
    if (photoPath.isEmpty) return fallback;
    return ClipOval(
      child: PrivatePhoto(
        path: photoPath,
        height: size,
        width: size,
        radius: size / 2,
        openViewer: false,
        fallback: fallback,
      ),
    );
  }
}

Future<void> showPersonPhotoSheet(
  BuildContext context, {
  required String title,
  required String name,
  required String photoPath,
  required String avatarPath,
  String? avatarCode,
  bool frontCamera = false,
  VoidCallback? onSaved,
  VoidCallback? onOpenAccount,
}) => showGlassSheet<void>(
  context,
  title: title,
  builder: (_) => _PersonPhotoEditor(
    title: title,
    name: name,
    photoPath: photoPath,
    avatarPath: avatarPath,
    avatarCode: avatarCode,
    frontCamera: frontCamera,
    onSaved: onSaved,
    onOpenAccount: onOpenAccount,
  ),
);

/// Renders the person photo editor element of person photo.
class _PersonPhotoEditor extends StatefulWidget {
  const _PersonPhotoEditor({
    required this.title,
    required this.name,
    required this.photoPath,
    required this.avatarPath,
    required this.avatarCode,
    required this.frontCamera,
    required this.onSaved,
    required this.onOpenAccount,
  });

  final String title;
  final String name;
  final String photoPath;
  final String avatarPath;
  final String? avatarCode;
  final bool frontCamera;
  final VoidCallback? onSaved;
  final VoidCallback? onOpenAccount;

  @override
  State<_PersonPhotoEditor> createState() => _PersonPhotoEditorState();
}

class _PersonPhotoEditorState extends State<_PersonPhotoEditor> {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('photos.save_failed'))),
        );
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
                      boxShadow: [
                        const BoxShadow(
                          color: AppSemanticColors.surfaceContent,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: AppSemanticColors.textPrimary.withValues(
                            alpha: .12,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
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
            return GestureDetector(
              onTap: () => setState(() {
                _code = code;
                _selected = null;
                _removed = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _code == code && _selected == null
                      ? [
                          const BoxShadow(
                            color: AppSemanticColors.textPrimary,
                            spreadRadius: 5,
                          ),
                          const BoxShadow(
                            color: AppSemanticColors.surfaceContent,
                            spreadRadius: 3,
                          ),
                        ]
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
        if (widget.onOpenAccount != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onOpenAccount!();
            },
            child: Text(context.tr('account.title')),
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
