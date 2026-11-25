import 'dart:async';

import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/widgets/home_add_plans.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The shared add sheet: a quick reading or dose, and a creation flow for
/// each area the account may edit in [circle] (the leader decides which).
/// What they save reaches the lists by itself, because the cubits follow
/// their repositories' change streams; nothing is reloaded here.
Future<void> showHomeAddSheet(
  BuildContext context, {
  required CareCircleSummary circle,
}) {
  final String circleId = circle.id;
  return showGlassSheet<void>(
    context,
    title: context.tr('add.title'),
    builder: (BuildContext sheetContext) => HomeAddSheetContent(
      circleId: circleId,
      onMedication: circle.canManageMedications
          ? () => _openFrom(
              sheetContext,
              context,
              CareItemRoutes.newMedication(circleId),
            )
          : null,
      onMeasurement: circle.canManageMeasurements
          ? () => _openFrom(
              sheetContext,
              context,
              CareItemRoutes.newMeasurement(circleId),
            )
          : null,
      onAppointment: circle.canManageAppointments
          ? () => _openFrom(
              sheetContext,
              context,
              CareItemRoutes.newAppointment(circleId),
            )
          : null,
      onReading: () {
        Navigator.of(sheetContext).pop();
        unawaited(showMeasurementReadingSheet(context));
      },
      onDose: () {
        Navigator.of(sheetContext).pop();
        unawaited(showExtraDoseSheet(context, circleId: circleId));
      },
    ),
  );
}

/// Closes the sheet and opens the form at [location].
void _openFrom(
  BuildContext sheetContext,
  BuildContext context,
  String location,
) {
  Navigator.of(sheetContext).pop();
  unawaited(context.push<bool>(location));
}

/// The content of the add sheet: the quick reading and dose, then the
/// plans. A plan whose callback is null is left out.
class HomeAddSheetContent extends StatelessWidget {
  const HomeAddSheetContent({
    required this.circleId,
    required this.onMedication,
    required this.onMeasurement,
    required this.onAppointment,
    required this.onReading,
    required this.onDose,
    super.key,
  });

  final String circleId;
  final VoidCallback? onMedication;
  final VoidCallback? onMeasurement;
  final VoidCallback? onAppointment;
  final VoidCallback onReading;
  final VoidCallback onDose;

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
        const SizedBox(height: AppSpacing.sm),
        HomeAddQuickAction(
          icon: CareIcons.pill,
          title: context.tr('add.dose_now'),
          hint: context.tr('add.dose_now_hint'),
          onTap: onDose,
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

/// A short line with a word in the middle, such as «إنشاء خطة».
class HomeAddLabelledLine extends StatelessWidget {
  const HomeAddLabelledLine({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final Color line = AppSemanticColors.textPrimary.withValues(alpha: 0.12);
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(height: AppSizes.divider, color: line),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppSemanticColors.textSupporting),
          ),
        ),
        Expanded(
          child: Divider(height: AppSizes.divider, color: line),
        ),
      ],
    );
  }
}

/// «سجّل قراءة الآن»: the quick action, on ink with a leaf icon tile.
class HomeAddQuickAction extends StatelessWidget {
  const HomeAddQuickAction({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: spoken('$title، $hint'),
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      color: AppSemanticColors.textPrimary,
      shape: AppRadius.shape(AppRadius.m),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: MergeSemantics(
            child: Row(
              children: homeAddQuickActionRow(
                context,
                icon: icon,
                title: title,
                hint: hint,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The icon tile of the quick action.
const double _tile = 48;

/// The row of the quick action: the leaf tile, the two lines of text, and
/// a chevron at the end.
List<Widget> homeAddQuickActionRow(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String hint,
}) {
  final TextTheme text = Theme.of(context).textTheme;
  return <Widget>[
    Container(
      width: _tile,
      height: _tile,
      decoration: ShapeDecoration(
        color: AppSemanticColors.accentLeaf,
        shape: AppRadius.shape(AppRadius.s),
      ),
      child: Icon(
        icon,
        size: AppSizes.icon,
        color: AppSemanticColors.textPrimary,
      ),
    ),
    const SizedBox(width: AppSpacing.md),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: text.titleLarge?.copyWith(
              color: AppSemanticColors.surfaceContent,
            ),
          ),
          Text(
            hint,
            style: text.bodySmall?.copyWith(
              color: AppSemanticColors.borderSubtle,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(width: AppSpacing.sm),
    const Icon(
      ArrowIcons.forward,
      size: AppSizes.iconSmall,
      color: AppSemanticColors.borderSubtle,
    ),
  ];
}
