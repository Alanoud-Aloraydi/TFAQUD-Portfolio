import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_square_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SimplifiedSquares extends StatelessWidget {
  const SimplifiedSquares({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SimplifiedSquare(
              dark: true,
              icon: CareVisuals.measurementIcon,
              iconColor: CareVisuals.measurementTile,
              title: context.tr('simplified_mode.record_measurement'),
              subtitle: context.tr('simplified_mode.record_measurement_sub'),
              onTap: () => context.push(Routes.simplifiedMeasure(circleId)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SimplifiedSquare(
              icon: CareIcons.firstAid,
              iconColor: SimplifiedColors.danger,
              title: context.tr('simplified_mode.emergency'),
              subtitle: context.tr('simplified_mode.emergency_sub'),
              onTap: () =>
                  context.push(Routes.simplifiedEmergencyCard(circleId)),
            ),
          ),
        ],
      ),
    );
  }
}

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
      color: dark ? SimplifiedColors.ink : SimplifiedColors.surface,
      side: dark
          ? BorderSide.none
          : const BorderSide(color: SimplifiedColors.line),
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: SimplifiedSquareContent(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        dark: dark,
      ),
    );
  }
}
