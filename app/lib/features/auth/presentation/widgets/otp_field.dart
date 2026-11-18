import 'package:app/features/auth/presentation/widgets/otp_boxes.dart';
import 'package:app/features/auth/presentation/widgets/otp_field_input.dart';
import 'package:app/features/auth/presentation/widgets/otp_hidden_field.dart';
import 'package:flutter/material.dart';

/// Code entry: [length] boxes drawn left to right, filled from the left.
/// One invisible text field on top receives the keyboard, so typing, delete,
/// and paste all work. iOS offers the code from the SMS above the keyboard
/// (one-time code autofill), and the last digit sends it: [onCompleted].
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.length,
    required this.value,
    required this.onChanged,
    this.onCompleted,
    this.hasError = false,
  });

  final int length;

  /// The digits typed so far, written 0-9.
  final String value;
  final ValueChanged<String> onChanged;

  /// Called once the last digit is in (typed, pasted or filled from the
  /// SMS), so the user does not have to press «تأكيد».
  final ValueChanged<String>? onCompleted;

  final bool hasError;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> with OtpFieldInput {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 64,
        child: Stack(
          children: <Widget>[
            OtpBoxes(
              length: widget.length,
              value: widget.value,
              focused: focus.hasFocus,
              hasError: widget.hasError,
            ),
            Positioned.fill(
              child: OtpHiddenField(
                controller: controller,
                focus: focus,
                length: widget.length,
                onChanged: entered,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
