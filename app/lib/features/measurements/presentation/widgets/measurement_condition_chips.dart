import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «ظروف القياس»: chips to choose none, one or more conditions of a reading
/// or a reading time. A meal state replaces the one already chosen; a
/// condition the form no longer offers («قبل النوم») stays while chosen.
class MeasurementConditionChips extends StatelessWidget {
  const MeasurementConditionChips({
    super.key,
    required this.kind,
    required this.selected,
    required this.onChanged,
    this.caption,
  });

  final MeasurementKind kind;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  /// A line above the chips: «اختر واحدًا أو أكثر».
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final List<String> offered = MeasurementConditions.offered(kind);
    final List<String> codes = <String>[
      ...offered,
      for (final String code in selected)
        if (!offered.contains(code)) code,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (caption != null) ...<Widget>[
          Text(
            caption!,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppSemanticColors.textSupporting),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        OptionChips(
          options: <ChipOption>[
            for (final String code in codes)
              ChipOption(code, context.tr('measurements.condition.$code')),
          ],
          isSelected: selected.contains,
          onTap: (code) =>
              onChanged(MeasurementConditions.toggle(selected, code)),
        ),
      ],
    );
  }
}

/// A reading's conditions on one line, «أخرى» in the reader's words when
/// they wrote some: «بعد جهد، بعد القهوة».
String readingConditionsText(
  BuildContext context,
  MeasurementReading reading,
) => <String>[
  for (final String code in reading.conditions)
    if (code == 'other' && reading.otherCondition != null)
      reading.otherCondition!
    else
      context.tr('measurements.condition.$code'),
].join('، ');

/// What the calendar shows under it for the chosen [day] of [month]: the
/// date, and its [readings] or a note that there are none.
List<Widget> measurementCalendarSelection(
  BuildContext context, {
  required int day,
  required CalendarMonth month,
  required List<MeasurementReading> readings,
  required String circleId,
}) => <Widget>[
  const SizedBox(height: AppSpacing.sm),
  Text(
    calendarDate(context, month.dayAt(day), year: false),
    style: Theme.of(context).textTheme.titleSmall,
  ),
  if (readings.isEmpty)
    EmptyStateNote(context.tr('measurements.no_readings'))
  else
    for (final MeasurementReading reading in readings) ...<Widget>[
      MeasurementReadingTile(reading: reading, circleId: circleId),
      const SizedBox(height: AppSpacing.xs),
    ],
];
