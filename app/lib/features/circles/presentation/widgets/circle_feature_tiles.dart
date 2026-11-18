import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/widgets/circle_feature_tile.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The two tiles under the patient card, side by side and of one height:
/// the medical file and the emergency card.
class CircleFeatureTiles extends StatelessWidget {
  const CircleFeatureTiles({
    super.key,
    required this.circleId,
    required this.medicalFile,
  });

  final String circleId;
  final MedicalFile? medicalFile;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: CircleFeatureTile(
              icon: CareIcons.fileText,
              iconColor: AppSemanticColors.textSupporting,
              title: context.tr('circles.file_title'),
              // A file with unknown answers says so, with the yellow «!».
              subtitle: (medicalFile?.needsFilling ?? false)
                  ? context.tr('medical_alert.tile')
                  : context.tr('circle_overview.file_hint'),
              attention: medicalFile?.needsFilling ?? false,
              onTap: () => context.push(Routes.medicalFile(circleId)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: CircleFeatureTile(
              icon: CareIcons.firstAid,
              iconColor: AppSemanticColors.statusError,
              title: context.tr('circles.card_title'),
              subtitle: context.tr('circle_overview.card_hint'),
              onTap: () => context.push(Routes.emergencyCard(circleId)),
            ),
          ),
        ],
      ),
    );
  }
}
