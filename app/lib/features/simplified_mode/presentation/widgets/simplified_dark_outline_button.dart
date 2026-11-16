import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// The quiet button of a dark screen («رجوع»): only its edge and its
/// words, since the app's outlined buttons are white.
class SimplifiedDarkOutlineButton extends StatelessWidget {
  const SimplifiedDarkOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        shape: const StadiumBorder(),
        backgroundColor: SimplifiedStyle.clear,
        foregroundColor: SimplifiedStyle.surface,
        side: const BorderSide(color: SimplifiedStyle.onDarkMuted, width: 1.5),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: SimplifiedStyle.head(
          SimplifiedStyle.body,
          color: SimplifiedStyle.surface,
        ),
      ),
    ),
  );
}
