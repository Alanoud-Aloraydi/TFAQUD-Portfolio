import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/features/circles/domain/emergency_number.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The red «اتصال بالإسعاف» button under the card; it calls
/// [EmergencyNumber.ambulance].
class AmbulanceButton extends StatelessWidget {
  const AmbulanceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () =>
          launchUrl(Uri(scheme: 'tel', path: EmergencyNumber.ambulance)),
      style: FilledButton.styleFrom(
        backgroundColor: AppSemanticColors.statusError,
        foregroundColor: AppSemanticColors.surfaceContent,
        minimumSize: const Size.fromHeight(AppSizes.button),
      ),
      icon: const Icon(AppIcons.siren, size: AppSizes.icon),
      label: Text(
        context.tr(
          'emergency_card.ambulance',
          args: <String>[EmergencyNumber.ambulance],
        ),
      ),
    );
  }
}
