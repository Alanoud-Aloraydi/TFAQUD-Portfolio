import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// A red-worded capsule for leaving or deleting the account.
class SimplifiedOutlinedDanger extends StatelessWidget {
  const SimplifiedOutlinedDanger({
    super.key,
    required this.label,
    required this.busy,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool busy;

  /// White behind it with a light edge; else only a red edge.
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        shape: const StadiumBorder(),
        backgroundColor: filled
            ? SimplifiedStyle.surface
            : SimplifiedStyle.clear,
        side: BorderSide(
          color: filled ? SimplifiedStyle.line : SimplifiedStyle.danger,
          width: filled ? 1 : 1.5,
        ),
        foregroundColor: SimplifiedStyle.danger,
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Text(
              label,
              style: SimplifiedStyle.head(
                SimplifiedStyle.body,
                color: SimplifiedStyle.danger,
              ),
            ),
    );
  }
}
