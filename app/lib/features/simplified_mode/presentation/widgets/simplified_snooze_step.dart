import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// A round «−» or «+» beside the ruler: five minutes less or more with
/// one tap, for a hand that slides a ruler less easily. The ruler itself
/// is the one slider a screen reader meets, so this is not read again.
class SimplifiedSnoozeStep extends StatelessWidget {
  const SimplifiedSnoozeStep({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;

  /// Null at the ruler's end: nothing less, or nothing more, to choose.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 64,
      height: 64,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: SimplifiedStyle.surface.withValues(alpha: .16),
          foregroundColor: SimplifiedStyle.surface,
          disabledBackgroundColor: SimplifiedStyle.surface.withValues(
            alpha: .06,
          ),
          disabledForegroundColor: SimplifiedStyle.onDarkMuted,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: 30),
      ),
    ),
  );
}
