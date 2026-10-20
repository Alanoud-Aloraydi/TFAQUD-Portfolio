import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Code entry: [length] boxes drawn left to right, filled from the left.
/// One invisible text field on top receives the keyboard, so typing, delete,
/// and paste all work.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.length,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final int length;

  /// The digits typed so far, written 0-9.
  final String value;
  final ValueChanged<String> onChanged;
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
                  if (i > 0) const SizedBox(width: 8),
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
                showCursor: false,
                enableInteractiveSelection: false,
                style: const TextStyle(color: Colors.transparent),
                cursorColor: Colors.transparent,
                inputFormatters: <TextInputFormatter>[
                  _DigitsFormatter(widget.length),
                ],
                onChanged: widget.onChanged,
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
    // Control borders use fieldBorder (3:1 contrast), as the other fields do.
    final Color border = hasError
        ? AppColors.danger
        : (isActive ? AppColors.brand : AppColors.fieldBorder);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
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
