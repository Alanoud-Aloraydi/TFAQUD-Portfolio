import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

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

/// The look of a [SimplifiedButton]. The three a task uses borrow the
/// detailed mode's colours ([TaskButtonRole]), so «أخذته الآن» is the same
/// violet, «ذكّرني لاحقًا» the same honey and «ما أخذتها» the same
/// grey in both modes; the rest are the mode's own.
enum SimplifiedButtonTone {
  primary,
  secondary,
  danger,
  dark,
  quiet,
  answer(TaskButtonRole.answer),
  later(TaskButtonRole.later),
  skip(TaskButtonRole.skip);

  const SimplifiedButtonTone([this.role]);

  /// The task role whose colours this tone borrows; null for the mode's
  /// own buttons.
  final TaskButtonRole? role;

  /// Its fill, the colour of its words, and its edge. A task's button has
  /// no edge, as in the detailed mode: its fill, words and icon say it.
  (Color, Color, BorderSide) get paint {
    if (role case final TaskButtonRole role) {
      return (role.fill, role.ink, BorderSide.none);
    }
    return switch (this) {
      primary => (
        SimplifiedColors.accentStrong,
        SimplifiedColors.surface,
        BorderSide.none,
      ),
      secondary => (
        SimplifiedColors.surface,
        SimplifiedColors.ink,
        const BorderSide(color: SimplifiedColors.control, width: 2),
      ),
      danger => (
        SimplifiedColors.danger,
        SimplifiedColors.surface,
        BorderSide.none,
      ),
      dark => (SimplifiedColors.ink, SimplifiedColors.surface, BorderSide.none),
      _ => (SimplifiedColors.chip, SimplifiedColors.ink, BorderSide.none),
    };
  }
}
