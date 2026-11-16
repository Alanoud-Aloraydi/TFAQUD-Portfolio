import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_interval_picker.dart';
import 'package:app/features/medications/presentation/widgets/medication_weekdays_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «أسبوعي | كل كم يوم» on the app's glass segmented control, and under it
/// the weekdays, or the number of days on a ruler right here (not in a
/// sheet). Apple's guidance for a segmented control is this case: two
/// closely related views of one choice, short labels, segments of equal
/// width.
class MedicationRepeatBlock extends StatelessWidget {
  const MedicationRepeatBlock({
    super.key,
    required this.data,
    required this.onChanged,
    this.issue,
    this.startsOn,
  });

  final ScheduleFormData data;
  final VoidCallback onChanged;
  final MedicationFormIssue? issue;
  final DateTime? startsOn;

  @override
  Widget build(BuildContext context) {
    final bool interval = data.repeat == ScheduleRepeat.interval;
    return InsetBlock(
      semanticLabel: context.tr('medications.repeat'),
      errorText: issue?.field == MedicationFormField.weekdays
          ? context.tr('medications.weekday_required')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassSegmentedControl<ScheduleRepeat>(
            segments: <ScheduleRepeat, String>{
              ScheduleRepeat.weekly: context.tr('medications.repeat_weekly'),
              ScheduleRepeat.interval: context.tr(
                'medications.repeat_interval',
              ),
            },
            selected: data.repeat,
            onChanged: (ScheduleRepeat repeat) {
              data.repeat = repeat;
              onChanged();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (interval)
            MedicationIntervalPicker(
              data: data,
              startsOn: startsOn,
              onChanged: onChanged,
            )
          else
            MedicationWeekdaysField(data: data, onChanged: onChanged),
        ],
      ),
    );
  }
}
