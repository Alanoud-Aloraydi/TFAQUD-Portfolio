import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One number of a reading: its name at the start, its box at the end. A
/// blood pressure's two numbers go one under the other, the upper number on
/// top as a monitor shows it, so they never swap sides on an Arabic page.
class ReadingNumberField extends StatelessWidget {
  const ReadingNumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.last = true,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  /// False for the upper number: the keyboard's button goes to the next.
  final bool last;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
      const SizedBox(width: AppSpacing.md),
      SizedBox(
        width: 132,
        child: TextField(
          controller: controller,
          // The level under the values follows what is typed.
          onChanged: (_) => onChanged(),
          keyboardType: TextInputType.number,
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.headlineMedium,
          inputFormatters: <TextInputFormatter>[
            const WesternDigitsFormatter(),
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: AppSemanticColors.surfaceContent,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
    ],
  );
}
