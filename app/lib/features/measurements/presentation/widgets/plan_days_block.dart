import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/forms/weekday_selector.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «الأيام» of a plan: the weekdays its readings are taken on.
class PlanDaysBlock extends StatelessWidget {
  const PlanDaysBlock({
    super.key,
    required this.days,
    required this.errorKey,
    required this.onEdit,
  });

  final Set<int> days;

  /// The form's refusal; «days_required» is said under the days.
  final String? errorKey;

  /// Runs a change of [days], clears the error and draws the form again.
  final void Function(VoidCallback change) onEdit;

  @override
  Widget build(BuildContext context) => FieldWithError(
    error: errorKey == 'measurements.days_required'
        ? context.tr(errorKey!)
        : null,
    child: InsetBlock(
      semanticLabel: context.tr('measurements.days'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('measurements.days')),
          const SizedBox(height: AppSpacing.sm),
          WeekdaySelector(
            selected: days,
            onChanged: (Set<int> chosen) => onEdit(() {
              days
                ..clear()
                ..addAll(chosen);
            }),
          ),
        ],
      ),
    ),
  );
}
