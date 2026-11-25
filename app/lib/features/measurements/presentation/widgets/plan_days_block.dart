import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/forms/weekday_selector.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_wheel_choice.dart';
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

/// «يبدأ» (a new plan) or «يسري من» (an edit): the first day, chosen on the
/// patient's calendar, never before the patient's today.
class PlanStartRow extends StatelessWidget {
  const PlanStartRow({
    super.key,
    required this.start,
    required this.isNew,
    required this.onPicked,
  });

  final DateTime start;
  final bool isNew;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    final String label = context.tr(
      isNew ? 'measurements.starts' : 'measurements.effective_start',
    );
    return InsetRow(
      label: label,
      value: calendarDate(context, start),
      onTap: () async {
        final earliest = PatientClockScope.of(context).today();
        final selected = await showTafaqodDateSheet(
          context,
          title: label,
          initialDate: start.isBefore(earliest) ? earliest : start,
          firstDate: earliest,
          lastDate: earliest.add(const Duration(days: 3650)),
        );
        if (selected != null && context.mounted) onPicked(selected);
      },
    );
  }
}
