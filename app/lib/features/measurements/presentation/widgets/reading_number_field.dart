import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One number of a reading in the design system's form row, as every text
/// field of the app: its name, then the number, which a tap anywhere on the
/// row starts typing, and its unit at the end. A blood pressure's two
/// numbers are two rows of one card, the upper number on top as a monitor
/// shows it, so they never swap sides on an Arabic page.
class ReadingNumberField extends StatelessWidget {
  const ReadingNumberField({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
    required this.onChanged,
    this.last = true,
    this.errorText,
  });

  final String label;

  /// «ملم زئبق» or «ملغ/دل».
  final String unit;
  final TextEditingController controller;
  final VoidCallback onChanged;

  /// False for the upper number: the keyboard's button goes to the next.
  final bool last;

  /// Shown under the row: the reading's numbers are out of range.
  final String? errorText;

  @override
  Widget build(BuildContext context) => InsetTextRow(
    label: label,
    controller: controller,
    // The level under the values follows what is typed.
    onChanged: (_) => onChanged(),
    keyboardType: TextInputType.number,
    textInputAction: last ? TextInputAction.done : TextInputAction.next,
    inputFormatters: <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(3),
    ],
    errorText: errorText,
    trailing: Text(
      unit,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: context.tokens.textSecondary),
    ),
  );
}
