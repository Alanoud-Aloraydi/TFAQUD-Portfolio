import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The top bar of the plan form: «إلغاء», the title of a new plan or an
/// edit, and «حفظ», which is off while [onSave] is null.
AppBar measurementPlanFormBar(
  BuildContext context, {
  required bool isNew,
  required VoidCallback? onSave,
}) => AppBar(
  automaticallyImplyLeading: false,
  centerTitle: true,
  titleSpacing: AppSpacing.lg,
  title: GlassSurface(
    borderRadius: BorderRadius.circular(AppRadius.capsule),
    child: SizedBox(
      height: 52,
      child: Row(
        children: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(context.tr('common.cancel')),
          ),
          Expanded(
            child: Text(
              context.tr(
                isNew ? 'measurements.new_plan' : 'measurements.edit_plan',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: FilledButton(
              onPressed: onSave,
              child: Text(context.tr('measurements.save')),
            ),
          ),
        ],
      ),
    ),
  ),
);
