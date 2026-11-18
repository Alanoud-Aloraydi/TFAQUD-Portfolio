import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/home/presentation/widgets/home_add_labelled_line.dart';
import 'package:app/features/home/presentation/widgets/home_add_plans.dart';
import 'package:app/features/home/presentation/widgets/home_add_quick_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The content of the add sheet: the quick reading, then the plans. A plan
/// whose callback is null is left out.
class HomeAddSheetContent extends StatelessWidget {
  const HomeAddSheetContent({
    required this.circleId,
    required this.onMedication,
    required this.onMeasurement,
    required this.onAppointment,
    required this.onReading,
    super.key,
  });

  final String circleId;
  final VoidCallback? onMedication;
  final VoidCallback? onMeasurement;
  final VoidCallback? onAppointment;
  final VoidCallback onReading;

  @override
  Widget build(BuildContext context) {
    final List<Widget> plans = homeAddPlanOptions(
      context,
      circleId: circleId,
      onMedication: onMedication,
      onMeasurement: onMeasurement,
      onAppointment: onAppointment,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        HomeAddQuickAction(
          icon: CareIcons.heartbeat,
          title: context.tr('add.reading_now'),
          hint: context.tr('add.reading_now_hint'),
          onTap: onReading,
        ),
        const SizedBox(height: AppSpacing.lg),
        HomeAddLabelledLine(label: context.tr('add.plans')),
        const SizedBox(height: AppSpacing.sm),
        Material(
          // Solid, so nothing under the sheet shades the last row.
          color: AppSemanticColors.surfaceContent,
          shape: AppRadius.shape(AppRadius.m),
          clipBehavior: Clip.antiAlias,
          child: Column(children: homeAddPlanRows(plans)),
        ),
      ],
    );
  }
}
