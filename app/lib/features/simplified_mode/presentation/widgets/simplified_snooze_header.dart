import 'package:app/core/l10n/duration_text.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// «متى أذكّرك؟», then, as the detailed sheet, how long («بعد 15 دقيقة»)
/// over the clock time it means, in this mode's largest type.
class SimplifiedSnoozeHeader extends StatelessWidget {
  const SimplifiedSnoozeHeader({
    super.key,
    required this.minutes,
    required this.clock,
  });

  /// What is chosen now; null when there is no room to put the task off.
  final int? minutes;

  /// «الساعة 6:27 مساءً», the time [minutes] means.
  final String clock;

  @override
  Widget build(BuildContext context) {
    const Color ink = SimplifiedColors.surface;
    return Column(
      children: <Widget>[
        Text(
          context.tr('simplified_mode.when_remind'),
          textAlign: TextAlign.center,
          style: SimplifiedStyle.head(28, color: ink),
        ),
        const SizedBox(height: 28),
        if (minutes case final int chosen) ...<Widget>[
          Text(
            afterDuration(context, chosen),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(SimplifiedStyle.hero, color: ink),
          ),
          Text(
            clock,
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.title,
              color: SimplifiedColors.onDarkMuted,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
