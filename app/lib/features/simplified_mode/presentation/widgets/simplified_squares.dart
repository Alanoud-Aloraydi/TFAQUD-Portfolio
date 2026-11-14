import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_square.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
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
              icon: AppIcons.firstAid,
              iconColor: SimplifiedStyle.danger,
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
