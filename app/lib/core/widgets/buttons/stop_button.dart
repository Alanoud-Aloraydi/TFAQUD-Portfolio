import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The end of something, last in its details: «إيقاف الدواء», «إيقاف
/// الخطة», «إلغاء الموعد». Red and outlined, with its [icon], as wide as
/// the details: the same look for all three, since all three end what was
/// planned and keep what was recorded. Whoever presses it is asked first.
class StopButton extends StatelessWidget {
  const StopButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = CupertinoIcons.stop_circle,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppSizes.button),
        foregroundColor: AppSemanticColors.statusError,
        side: const BorderSide(color: AppSemanticColors.statusError),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: AppSizes.iconSmall),
      label: Text(label),
    ),
  );
}
