import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_saving.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/reading_conditions_section.dart';
import 'package:app/features/measurements/presentation/widgets/reading_time_and_note.dart';
import 'package:app/features/measurements/presentation/widgets/reading_values_section.dart';
import 'package:easy_localization/easy_localization.dart';
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

/// «حفظ القراءة», off while it is being saved ([onPressed] null).
class ReadingSaveButton extends StatelessWidget {
  const ReadingSaveButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(context.tr('measurements.save_reading')),
      ),
    ),
  );
}
