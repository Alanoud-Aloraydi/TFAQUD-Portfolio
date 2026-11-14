import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// One choice, «بعد ١٥ دقيقة» over the clock time it means; a screen reader
/// hears both as one button. Disabled ([onTap] null) while one is saved.
class SimplifiedSnoozeChoice extends StatelessWidget {
  const SimplifiedSnoozeChoice({
    super.key,
    required this.label,
    required this.clock,
    this.onTap,
  });

  final String label;
  final String clock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(SimplifiedStyle.radius);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$label، $clock',
      excludeSemantics: true,
      child: Material(
        color: SimplifiedStyle.surface.withValues(alpha: .1),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 92,
              minWidth: double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: SimplifiedStyle.head(
                      SimplifiedStyle.headline,
                      color: SimplifiedStyle.surface,
                    ),
                  ),
                  Text(
                    clock,
                    textAlign: TextAlign.center,
                    style: SimplifiedStyle.text(
                      SimplifiedStyle.caption,
                      color: SimplifiedStyle.onDarkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
