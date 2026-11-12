import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The shared add sheet: a quick reading, and a creation flow for each area
/// the account may edit in [circle] (the circle's leader decides which).
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
    builder: (BuildContext sheetContext) => _HomeAddSheet(
      circleId: circleId,
      onMedication: circle.canManageMedications
          ? () =>
                _openFrom(sheetContext, context, Routes.newMedication(circleId))
          : null,
      onMeasurement: circle.canManageMeasurements
          ? () => _openFrom(
              sheetContext,
              context,
              Routes.newMeasurement(circleId),
            )
          : null,
      onAppointment: circle.canManageAppointments
          ? () => _openFrom(
              sheetContext,
              context,
              Routes.newAppointment(circleId),
            )
          : null,
      onReading: () {
        Navigator.of(sheetContext).pop();
        unawaited(showMeasurementReadingSheet(context));
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

/// The content of the add sheet: the quick reading, then the plans. A plan
/// whose callback is null is left out.
class _HomeAddSheet extends StatelessWidget {
  const _HomeAddSheet({
    required this.circleId,
    required this.onMedication,
    required this.onMeasurement,
    required this.onAppointment,
    required this.onReading,
  });

  final String circleId;
  final VoidCallback? onMedication;
  final VoidCallback? onMeasurement;
  final VoidCallback? onAppointment;
  final VoidCallback onReading;

  @override
  Widget build(BuildContext context) {
    final List<Widget> plans = <Widget>[
      if (onMedication case final VoidCallback open)
        _PlanOption(
          icon: AppIcons.pill,
          title: context.tr('add.medication'),
          hint: CareVoice.tr(context, circleId, 'add.medication_hint'),
          onTap: open,
        ),
      if (onMeasurement case final VoidCallback open)
        _PlanOption(
          icon: AppIcons.listPlus,
          title: context.tr('add.measurement'),
          hint: context.tr('add.measurement_hint'),
          onTap: open,
        ),
      if (onAppointment case final VoidCallback open)
        _PlanOption(
          icon: AppIcons.calendarPlus,
          title: context.tr('add.appointment'),
          hint: context.tr('add.appointment_hint'),
          onTap: open,
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _QuickAction(
          icon: AppIcons.heartbeat,
          title: context.tr('add.reading_now'),
          hint: context.tr('add.reading_now_hint'),
          onTap: onReading,
        ),
        const SizedBox(height: AppSpacing.lg),
        _LabelledLine(label: context.tr('add.plans')),
        const SizedBox(height: AppSpacing.sm),
        Material(
          // Solid, so nothing under the sheet shades the last row.
          color: AppSemanticColors.surfaceContent,
          shape: AppRadius.shape(AppRadius.m),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < plans.length; i++) ...<Widget>[
                if (i > 0) const _RowDivider(),
                plans[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// «سجّل قراءة الآن»: the quick action, on ink with a leaf icon tile.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  static const double _tile = 48;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title، $hint',
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
            child: Row(
              children: <Widget>[
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
                  AppIcons.forward,
                  size: AppSizes.iconSmall,
                  color: AppSemanticColors.borderSubtle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A short line with a word in the middle, such as «إنشاء خطة».
class _LabelledLine extends StatelessWidget {
  const _LabelledLine({required this.label});

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

/// One plan: an icon tile, the name and what it does, and a chevron.
class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  static const double _tile = AppSizes.avatar;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title، $hint',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: _tile,
                height: _tile,
                decoration: ShapeDecoration(
                  color: AppSemanticColors.surfaceContent,
                  shape: AppRadius.shape(AppRadius.s),
                ),
                child: Icon(
                  icon,
                  size: AppSizes.iconSmall,
                  color: AppSemanticColors.textSupporting,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: text.titleSmall),
                    Text(
                      hint,
                      style: text.bodySmall?.copyWith(
                        color: AppSemanticColors.textSupporting,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                AppIcons.forward,
                size: AppSizes.iconSmall,
                color: AppSemanticColors.borderControlBase,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The line between two plans, from the start of their text.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: AppSizes.divider,
    indent: AppSpacing.lg + AppSizes.avatar + AppSpacing.md,
    color: AppSemanticColors.textPrimary.withValues(alpha: 0.08),
  );
}
