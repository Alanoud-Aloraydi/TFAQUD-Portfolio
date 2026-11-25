import 'package:app/features/simplified_mode/presentation/widgets/simplified_button_tone.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

export 'package:app/features/simplified_mode/presentation/widgets/simplified_button_tone.dart';

/// The mode's capsule button, full width and at least 72 high.
class SimplifiedButton extends StatelessWidget {
  const SimplifiedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = SimplifiedButtonTone.primary,
    this.icon,
  });

  final String label;

  /// Null shows the button disabled.
  final VoidCallback? onPressed;
  final SimplifiedButtonTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color text, BorderSide side) = tone.paint;
    // At least [SimplifiedStyle.action] high, and taller when a large text
    // size wraps the label, so it is never cut off.
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(SimplifiedStyle.action),
          backgroundColor: fill,
          foregroundColor: text,
          disabledBackgroundColor: SimplifiedColors.disabled,
          shape: StadiumBorder(side: side),
          padding: const EdgeInsets.symmetric(
            horizontal: SimplifiedStyle.pad,
            vertical: 12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 28),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: SimplifiedStyle.head(SimplifiedStyle.title, color: text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
