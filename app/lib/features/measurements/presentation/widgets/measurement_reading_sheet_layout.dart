import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_saving.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_scope.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_values.dart';
import 'package:app/features/measurements/presentation/widgets/reading_conditions_section.dart';
import 'package:app/features/measurements/presentation/widgets/reading_save_button.dart';
import 'package:app/features/measurements/presentation/widgets/reading_time_and_note.dart';
import 'package:app/features/measurements/presentation/widgets/reading_values_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The reading sheet, from what it holds.
mixin MeasurementReadingSheetLayout
    on
        MeasurementReadingSheetScope,
        MeasurementReadingSheetValues,
        MeasurementReadingSheetSaving {
  @override
  Widget build(BuildContext context) {
    // The glass sheet draws the title, scrolls, and stays above the
    // keyboard.
    final NormalRange? range = context
        .watch<MeasurementRangesCubit>()
        .state
        .ranges
        ?.of(kind, mealState);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReadingValuesSection(
              kind: kind,
              onKindChanged: widget.occurrence == null ? changeKind : null,
              systolic: systolic,
              diastolic: diastolic,
              glucose: glucose,
              onChanged: () => setState(() => errorKey = null),
              outOfRange: outOfRangeKey,
              range: range,
              level: range == null ? null : levelIn(range),
            ),
            const SizedBox(height: AppSpacing.lg),
            ReadingConditionsSection(
              kind: kind,
              selected: conditions,
              otherController: otherCondition,
              maxLength: MeasurementReadingSheetScope.otherConditionLength,
              onChanged: (value) => setState(() => conditions = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            ReadingTimeAndNote(
              time: time,
              onPicked: (value) => setState(() => picked = value),
              noteController: note,
              errorKey: outOfRangeKey == null ? errorKey : null,
            ),
          ],
        ),
        ReadingSaveButton(onPressed: saving ? null : save),
      ],
    );
  }
}
