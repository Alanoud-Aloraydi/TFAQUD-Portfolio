import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/overlays/choice_row.dart';
import 'package:app/core/widgets/overlays/skip_reason_option.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
