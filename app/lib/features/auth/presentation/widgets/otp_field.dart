import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _OtpFieldState extends State<OtpField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void didUpdateWidget(OtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The cubit cleared or changed the code (for example after a wrong code).
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String digits) {
    widget.onChanged(digits);
    if (digits.length == widget.length) widget.onCompleted?.call(digits);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? digitStyle = Theme.of(context).textTheme.headlineMedium;
    final int filled = widget.value.length;
    final int active = filled < widget.length ? filled : widget.length - 1;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 64,
        child: Stack(
          children: <Widget>[
            Row(
              children: <Widget>[
                for (int i = 0; i < widget.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _OtpBox(
                      digit: i < filled ? widget.value[i] : '',
                      isActive: _focus.hasFocus && i == active,
                      hasError: widget.hasError,
                      style: digitStyle,
                    ),
                  ),
                ],
              ],
            ),
            Positioned.fill(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
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
                inputFormatters: <TextInputFormatter>[
                  _DigitsFormatter(widget.length),
                ],
                onChanged: _changed,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps only digits (Western or Arabic-Indic) and cuts the text at [length].
class _DigitsFormatter extends TextInputFormatter {
  _DigitsFormatter(this.length);

  final int length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = ArabicDigits.digitsOnly(newValue.text);
    if (digits.length > length) digits = digits.substring(0, length);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

/// Renders the otp box element of otp field.
class _OtpBox extends StatelessWidget {
  const _OtpBox({
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
