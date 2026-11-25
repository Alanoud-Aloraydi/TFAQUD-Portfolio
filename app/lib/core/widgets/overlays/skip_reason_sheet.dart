import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The one sheet that skips a dose or a reading: the question as its
/// [title], «(اختياري)» under it ([message]), the [reasons] with a check
/// on the chosen one, a row to write «سبب آخر» in, and [confirmLabel]. Returns
/// null when the person closes it.
Future<SkipReasonChoice?> showSkipReasonSheet(
  BuildContext context, {
  required String title,
  required String message,
  required List<SkipReasonOption> reasons,
  required String noteLabel,
  required String confirmLabel,
}) => showGlassSheet<SkipReasonChoice>(
  context,
  title: title,
  message: message,
  builder: (_) => SkipReasonBody(
    reasons: reasons,
    noteLabel: noteLabel,
    confirmLabel: confirmLabel,
  ),
);

/// What a [showSkipReasonSheet] holds: the reasons with a check on the
/// chosen one, a text box for «سبب آخر» once it is chosen, and the button
/// that closes the sheet with the choice.
class SkipReasonBody extends StatefulWidget {
  const SkipReasonBody({
    super.key,
    required this.reasons,
    required this.noteLabel,
    required this.confirmLabel,
  });

  final List<SkipReasonOption> reasons;
  final String noteLabel;
  final String confirmLabel;

  @override
  State<SkipReasonBody> createState() => _SkipReasonBodyState();
}

class _SkipReasonBodyState extends State<SkipReasonBody> {
  /// The reason typed by hand.
  static const String _other = 'other';

  final TextEditingController _note = TextEditingController();
  String? _code;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (final SkipReasonOption reason in widget.reasons)
        ChoiceRow(
          label: reason.label,
          selected: reason.code == _code,
          onTap: () =>
              setState(() => _code = reason.code == _code ? null : reason.code),
        ),
      if (_code == _other) ...<Widget>[
        const SizedBox(height: AppSpacing.sm),
        LabeledTextField(
          label: context.tr('common.reason'),
          helperText: widget.noteLabel,
          controller: _note,
          autofocus: true,
          maxLength: 250,
          maxLines: 3,
          onChanged: (_) {},
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      PillButton(label: widget.confirmLabel, onPressed: _confirm),
    ],
  );

  void _confirm() {
    final String note = _note.text.trim();
    Navigator.pop<SkipReasonChoice>(context, (
      code: _code,
      note: _code == _other && note.isNotEmpty ? note : null,
    ));
  }
}

/// One reason of a [showSkipReasonSheet]: its API code and its words.
class SkipReasonOption {
  const SkipReasonOption(this.code, this.label);

  final String code;
  final String label;
}

/// What the person chose: the reason's code (null for none) and, for
/// «سبب آخر» (`other`), what they typed.
typedef SkipReasonChoice = ({String? code, String? note});

/// One choice of a list in a sheet, as an iOS list row: its words, and a
/// check mark at the end of the chosen one. Every sheet that offers a list
/// of choices (a skip reason, a unit) uses this row.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: 0,
    contentPadding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.sm,
    ),
    onTap: onTap,
    selected: selected,
    title: Text(label),
    trailing: selected
        ? const Icon(ActionIcons.check, color: AppSemanticColors.textPrimary)
        : null,
  );
}
