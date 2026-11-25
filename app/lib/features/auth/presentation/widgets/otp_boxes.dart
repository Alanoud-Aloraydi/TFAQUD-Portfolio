import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The [length] boxes of the code, filled from the left with [value]; the
/// box the next digit goes in is marked while the field has focus.
class OtpBoxes extends StatelessWidget {
  const OtpBoxes({
    super.key,
    required this.length,
    required this.value,
    required this.focused,
    required this.hasError,
  });

  final int length;
  final String value;
  final bool focused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final TextStyle? digitStyle = Theme.of(context).textTheme.headlineMedium;
    final int filled = value.length;
    final int active = filled < length ? filled : length - 1;
    return Row(
      children: <Widget>[
        for (int i = 0; i < length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OtpBox(
              digit: i < filled ? value[i] : '',
              isActive: focused && i == active,
              hasError: hasError,
              style: digitStyle,
            ),
          ),
        ],
      ],
    );
  }
}

class OtpBox extends StatelessWidget {
  const OtpBox({
    super.key,
    required this.digit,
    required this.isActive,
    required this.hasError,
    required this.style,
  });

  final String digit;
  final bool isActive;
  final bool hasError;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // Control borders use stone (3.98:1), as the other fields do; the active
    // box shows the focus color.
    final Color border = hasError
        ? AppSemanticColors.statusError
        : (isActive ? context.tokens.focus : context.tokens.borderControl);
    return AnimatedContainer(
      duration: AppMotion.fieldFeedback,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(
          color: border,
          width: (isActive || hasError) ? 2 : 1,
        ),
      ),
      child: Text(digit, style: style),
    );
  }
}
