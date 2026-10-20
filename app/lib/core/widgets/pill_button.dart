import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Full-width pill button of the sign-in and account setup pages.
/// While [isLoading] is true it shows a spinner and ignores taps.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = onPressed == null
        ? null
        // An empty function keeps the normal color while the spinner shows.
        : (isLoading ? () {} : onPressed);
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(48),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onBrand,
                ),
              )
            : Text(label),
      ),
    );
  }
}
