import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:flutter/material.dart';

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
