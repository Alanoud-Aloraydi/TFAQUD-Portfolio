import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_saving.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/reading_titles.dart';
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

/// The end of the reading sheet: the time of the reading, the recorder's
/// note, and why the reading was not saved, when it was not ([errorKey]).
/// The server's refusal stays here, above the button: a toast would be
/// hidden behind the sheet.
class ReadingTimeAndNote extends StatelessWidget {
  const ReadingTimeAndNote({
    super.key,
    required this.time,
    required this.onPicked,
    required this.noteController,
    this.errorKey,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onPicked;
  final TextEditingController noteController;
  final String? errorKey;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReadingTimeGroup(time: time, onPicked: onPicked),
      const SizedBox(height: AppSpacing.lg),
      ReadingNoteGroup(controller: noteController),
      if (errorKey != null) ReadingErrorNote(errorKey: errorKey!),
    ],
  );
}

/// Why the reading was not saved, in the error colour.
class ReadingErrorNote extends StatelessWidget {
  const ReadingErrorNote({super.key, required this.errorKey});

  final String errorKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Text(
      context.tr(errorKey),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

/// «ملاحظة» of the reading sheet: a line of the recorder's own words.
class ReadingNoteGroup extends StatelessWidget {
  const ReadingNoteGroup({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => InsetGroup(
    children: [
      InsetTextRow(
        label: context.tr('measurements.note'),
        controller: controller,
        onChanged: (_) {},
        maxLength: 250,
      ),
    ],
  );
}

/// The conditions of the reading sheet, and «أخرى» in the reader's own
/// words once it is chosen, as the medical file's «أخرى» takes them.
class ReadingConditionsSection extends StatelessWidget {
  const ReadingConditionsSection({
    super.key,
    required this.kind,
    required this.selected,
    required this.otherController,
    required this.maxLength,
    required this.onChanged,
  });

  final MeasurementKind kind;
  final List<String> selected;
  final TextEditingController otherController;
  final int maxLength;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReadingConditionsGroup(
        kind: kind,
        selected: selected,
        onChanged: onChanged,
      ),
      if (selected.contains('other')) ...[
        const SizedBox(height: AppSpacing.md),
        ReadingOtherCondition(
          controller: otherController,
          maxLength: maxLength,
        ),
      ],
    ],
  );
}

/// «أخرى» of a reading's conditions, in the reader's own words.
class ReadingOtherCondition extends StatelessWidget {
  const ReadingOtherCondition({
    super.key,
    required this.controller,
    required this.maxLength,
  });

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) => LabeledTextField(
    label: context.tr('measurements.other_condition'),
    helperText: context.tr('measurements.other_condition_hint'),
    controller: controller,
    maxLength: maxLength,
    textInputAction: TextInputAction.done,
    onChanged: (_) {},
  );
}

/// «ظروف القياس (اختياري)» of the reading sheet: the chips of its kind.
class ReadingConditionsGroup extends StatelessWidget {
  const ReadingConditionsGroup({
    super.key,
    required this.kind,
    required this.selected,
    required this.onChanged,
  });

  final MeasurementKind kind;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => InsetGroup(
    header: context.tr('measurements.condition_optional'),
    children: [
      InsetBlock(
        semanticLabel: context.tr('measurements.condition_optional'),
        child: MeasurementConditionChips(
          kind: kind,
          selected: selected,
          caption: context.tr('measurements.conditions_hint'),
          onChanged: onChanged,
        ),
      ),
    ],
  );
}
