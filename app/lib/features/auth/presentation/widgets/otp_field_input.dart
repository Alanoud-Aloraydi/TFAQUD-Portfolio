import 'package:app/features/auth/presentation/widgets/otp_field.dart';
import 'package:flutter/material.dart';

/// The text and the focus of an [OtpField]: the typed digits follow the
/// cubit's, and a change of focus redraws the boxes.
mixin OtpFieldInput on State<OtpField> {
  late final TextEditingController controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void didUpdateWidget(OtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The cubit cleared or changed the code (for example after a wrong code).
    if (controller.text != widget.value) {
      controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    focus.removeListener(_onFocusChanged);
    focus.dispose();
    controller.dispose();
    super.dispose();
  }

  /// Hands the digits on, and sends them once the last one is in.
  void entered(String digits) {
    widget.onChanged(digits);
    if (digits.length == widget.length) widget.onCompleted?.call(digits);
  }
}
