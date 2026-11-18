import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/auth/presentation/widgets/otp_digits_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The invisible text field over the code's boxes. It receives the keyboard,
/// so typing, delete and paste all work.
class OtpHiddenField extends StatelessWidget {
  const OtpHiddenField({
    super.key,
    required this.controller,
    required this.focus,
    required this.length,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final int length;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focus,
      autofocus: true,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      // iOS reads the code from the SMS and offers it above the
      // keyboard; one tap fills every box.
      autofillHints: const <String>[AutofillHints.oneTimeCode],
      showCursor: false,
      enableInteractiveSelection: false,
      style: const TextStyle(color: AppSemanticColors.transparent),
      cursorColor: AppSemanticColors.transparent,
      inputFormatters: <TextInputFormatter>[OtpDigitsFormatter(length)],
      onChanged: onChanged,
      decoration: const InputDecoration(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        counterText: '',
      ),
    );
  }
}
