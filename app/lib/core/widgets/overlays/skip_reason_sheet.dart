import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/overlays/choice_row.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:flutter/material.dart';

/// One reason of a [showSkipReasonSheet]: its API code and its words.
class SkipReasonOption {
  const SkipReasonOption(this.code, this.label);

  final String code;
  final String label;
}

/// What the person chose: the reason's code (null for none) and, for
/// «سبب آخر» (`other`), what they typed.
typedef SkipReasonChoice = ({String? code, String? note});

/// The one sheet that skips a dose or a reading: the question as its
/// [title], «(اختياري)» under it ([message]), the [reasons] with a check
/// on the chosen one, a text box for «سبب آخر», and [confirmLabel]. Returns
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
  builder: (_) => _SkipReasonBody(
    reasons: reasons,
    noteLabel: noteLabel,
    confirmLabel: confirmLabel,
  ),
);

class _SkipReasonBody extends StatefulWidget {
  const _SkipReasonBody({
    required this.reasons,
    required this.noteLabel,
    required this.confirmLabel,
  });

  final List<SkipReasonOption> reasons;
  final String noteLabel;
  final String confirmLabel;

  @override
  State<_SkipReasonBody> createState() => _SkipReasonBodyState();
}

class _SkipReasonBodyState extends State<_SkipReasonBody> {
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
        TextField(
          controller: _note,
          autofocus: true,
          maxLength: 250,
          inputFormatters: const <CodePointLengthFormatter>[
            CodePointLengthFormatter(250),
          ],
          decoration: InputDecoration(labelText: widget.noteLabel),
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
