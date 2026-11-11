import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The minutes after which a dose or reading counts as missed, typed freely
/// between [PlanLimits.minMissedAfterMinutes] and
/// [PlanLimits.maxMissedAfterMinutes]. The same row serves every kind of
/// plan; [onChanged] gets null while the text is not a whole number.
class MissedAfterField extends StatefulWidget {
  const MissedAfterField({
    super.key,
    required this.label,
    required this.minutes,
    required this.onChanged,
    this.focusNode,
    this.showError = false,
  });

  final String label;
  final int? minutes;
  final ValueChanged<int?> onChanged;
  final FocusNode? focusNode;

  /// Shows the range under the row even before the user has typed.
  final bool showError;

  @override
  State<MissedAfterField> createState() => _MissedAfterFieldState();
}

class _MissedAfterFieldState extends State<MissedAfterField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.minutes?.toString() ?? '',
  );

  /// Whether the user has typed, so an emptied field is told apart from one
  /// not yet used.
  bool _touched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool invalid =
        !PlanLimits.isValidMissedAfter(widget.minutes) &&
        (widget.showError || _touched);
    return InsetTextRow(
      label: widget.label,
      controller: _controller,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      maxLength: 3,
      textInputAction: TextInputAction.done,
      hint: context.tr('plan_limits.minutes_hint'),
      errorText: invalid
          ? context.tr(
              'plan_limits.missed_after_range',
              args: <String>[
                '${PlanLimits.minMissedAfterMinutes}',
                '${PlanLimits.maxMissedAfterMinutes}',
              ],
            )
          : null,
      onChanged: (String text) {
        _touched = true;
        widget.onChanged(int.tryParse(text));
      },
    );
  }
}
