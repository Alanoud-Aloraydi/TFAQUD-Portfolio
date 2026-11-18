import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/auth/presentation/widgets/otp_box.dart';
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
