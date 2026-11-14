import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

class SimplifiedSquare extends StatelessWidget {
  const SimplifiedSquare({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: spoken('$title. $subtitle'),
      // The tap lives on the card inside, which is excluded below, so the
      // node that VoiceOver lands on needs the action of its own.
      onTap: onTap,
      excludeSemantics: true,
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    return SimplifiedCard(
      color: dark ? SimplifiedStyle.ink : SimplifiedStyle.surface,
      side: dark
          ? BorderSide.none
          : const BorderSide(color: SimplifiedStyle.line),
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: SimplifiedStyle.head(
                SimplifiedStyle.body,
                color: dark ? SimplifiedStyle.surface : SimplifiedStyle.ink,
              ),
            ),
            Text(
              subtitle,
              style: SimplifiedStyle.text(
                SimplifiedStyle.caption,
                color: dark
                    ? SimplifiedStyle.onDarkMuted
                    : SimplifiedStyle.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
