import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// One answer on a dark screen («نسيتها»): a wide, quiet card with its
/// words in the middle, at least 76 high and taller when a large text
/// wraps. Disabled ([onTap] null) while an answer is being saved.
class SimplifiedDarkChoice extends StatelessWidget {
  const SimplifiedDarkChoice({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(SimplifiedStyle.radius);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: SimplifiedColors.surface.withValues(alpha: .1),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 76,
              minWidth: double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: SimplifiedStyle.head(
                    SimplifiedStyle.headline,
                    color: SimplifiedColors.surface,
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
