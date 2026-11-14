import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «لماذا بطاقة منفصلة؟»: the medical file is for the family; the card is
/// for a stranger in a hurry.
class EmergencyWhySeparate extends StatelessWidget {
  const EmergencyWhySeparate({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.inset),
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(AppIcons.info, size: AppSizes.iconSmall),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.tr('emergency_card.why_title'),
                style: text.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(context.tr('emergency_card.why_text'), style: text.bodySmall),
        ],
      ),
    );
  }
}
