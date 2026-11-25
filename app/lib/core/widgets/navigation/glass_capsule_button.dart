import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:flutter/material.dart';

/// Glass capsule with a short label and an icon after it, such as the circle
/// switcher in the middle of the top bar. At least 44 high. [semanticLabel]
/// is what VoiceOver reads, so a long name cut short on screen is still read
/// in full.
class GlassCapsuleButton extends StatelessWidget {
  const GlassCapsuleButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
    this.leading,
    this.onLeadingPressed,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final Widget? leading;
  final VoidCallback? onLeadingPressed;

  /// Null keeps the capsule visible but inert.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: spoken(semanticLabel),
      onTap: onPressed,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSizes.touch,
          minWidth: AppSizes.touch,
        ),
        child: GlassSurface(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppSizes.touch / 2),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: glassCapsuleChildren(
                    label: label,
                    icon: icon,
                    leading: leading,
                    onLeadingPressed: onLeadingPressed,
                    text: text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
