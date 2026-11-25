import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_skip_other.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «لماذا لم تأخذها؟» over the medicine's name, then the reasons; «سبب
/// آخر» opens a field to write it. The reason is never required, so no
/// answer blocks the record.
class SimplifiedSkipBody extends StatefulWidget {
  const SimplifiedSkipBody({
    super.key,
    required this.name,
    required this.saving,
    required this.onReason,
  });

  /// The medicine that was not taken.
  final String name;
  final bool saving;

  /// The reason, and with «سبب آخر» what the patient wrote (null if empty).
  final void Function(DoseSkipReason reason, String? note) onReason;

  @override
  State<SimplifiedSkipBody> createState() => _SimplifiedSkipBodyState();
}

class _SimplifiedSkipBodyState extends State<SimplifiedSkipBody> {
  final TextEditingController _note = TextEditingController();
  bool _writing = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final String note = _note.text.trim();
    widget.onReason(DoseSkipReason.other, note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      simplifiedSkipQuestion(context, widget.name),
      const SizedBox(height: 28),
      if (_writing)
        ...simplifiedSkipOther(
          context,
          note: _note,
          onSave: widget.saving ? null : _save,
        )
      else
        ...simplifiedSkipReasons(
          context,
          saving: widget.saving,
          onReason: (DoseSkipReason reason) => widget.onReason(reason, null),
          onOther: () => setState(() => _writing = true),
        ),
    ],
  );
}

/// «لماذا لم تأخذها؟» over the medicine's [name], read as one sentence.
Widget simplifiedSkipQuestion(BuildContext context, String name) =>
    MergeSemantics(
      child: Column(
        children: <Widget>[
          Text(
            context.tr('simplified_mode.skip_question'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(
              SimplifiedStyle.display,
              color: SimplifiedColors.surface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.title,
              color: SimplifiedColors.onDarkMuted,
            ),
          ),
        ],
      ),
    );
