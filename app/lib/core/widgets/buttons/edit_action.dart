import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The one way to edit, wherever the app offers it: «✎ تعديل» where the
/// row has space for the word, as «الملف الصحي» shows it, and the pencil
/// alone where it does not.
///
/// The app had three shapes for this one errand — a chip on «الملف
/// الصحي», a text button on the plan cards, a bare pencil elsewhere. The
/// word is what is given up when the room runs out, never the meaning:
/// either shape says [tooltip] on a long press and to a screen reader
/// («تعديل بيانات الدواء»), since «تعديل» alone does not say of what.
class EditAction extends StatelessWidget {
  const EditAction({
    super.key,
    required this.onPressed,
    required this.tooltip,
    this.compact = false,
  });

  /// The pencil alone, for a row whose end is already taken: the status
  /// badge on a plan card, the three lines of a contact tile.
  const EditAction.pen({
    super.key,
    required this.onPressed,
    required this.tooltip,
  }) : compact = true;

  final VoidCallback onPressed;

  /// What this edits, said on a long press and to a screen reader.
  final String tooltip;

  /// The pencil alone. A [Row] gives a child that does not flex no width
  /// to measure against, so a row that is full of other things says so
  /// here; [_roomForWord] decides the rest.
  final bool compact;

  /// Below this the word is dropped: «تعديل» beside the pencil needs
  /// about this much before the label wraps or clips.
  static const double _roomForWord = 112;

  @override
  Widget build(BuildContext context) => Semantics(
    // One node for either shape, saying the errand once and with its
    // vowels: the words, the icon and the tooltip would each be read.
    button: true,
    label: spoken(tooltip),
    excludeSemantics: true,
    onTap: onPressed,
    child: compact ? _pen(context) : _adaptive(context),
  );

  Widget _adaptive(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints room) {
      // Enlarged text needs the room the word would have taken.
      final bool enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final bool fits =
          !room.maxWidth.isFinite || room.maxWidth >= _roomForWord;
      return !enlarged && fits ? _chip(context) : _pen(context);
    },
  );

  Widget _chip(BuildContext context) => ActionChip(
    avatar: const Icon(
      ActionIcons.pencil,
      size: AppSizes.iconSmall,
      color: AppSemanticColors.textPrimary,
    ),
    label: Text(context.tr('common.edit')),
    tooltip: tooltip,
    backgroundColor: AppSemanticColors.selectedSurface,
    side: BorderSide.none,
    onPressed: onPressed,
  );

  Widget _pen(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    padding: const EdgeInsets.all(AppSpacing.xs),
    color: AppSemanticColors.textPrimary,
    icon: const Icon(ActionIcons.pencil, size: AppSizes.iconSmall),
  );
}
