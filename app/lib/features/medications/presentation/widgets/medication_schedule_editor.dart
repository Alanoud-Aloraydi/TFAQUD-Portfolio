import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/forms/weekday_selector.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_choice_button.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/ruler_picker.dart';
import 'package:app/features/medications/presentation/widgets/stepper_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One schedule row inside the medicine's grouped list.
class MedicationScheduleEditor extends StatelessWidget {
  const MedicationScheduleEditor({
    super.key,
    required this.index,
    required this.data,
    required this.units,
    required this.onChanged,
    this.onRemove,
    this.issue,
    this.startsOn,
  });

  final int index;
  final ScheduleFormData data;
  final List<DoseUnit> units;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  final MedicationFormIssue? issue;

  /// The day the treatment starts, where «كل كم يوم» counts from.
  final DateTime? startsOn;

  /// The largest dose the stepper reaches.
  static const double _maxDose = 999;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? remove = onRemove;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.lg,
            end: AppSpacing.sm,
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(
                    'medications.schedule_number',
                    args: [(index + 1).toString()],
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (remove != null)
                IconButton(
                  tooltip: context.tr('medications.remove_schedule'),
                  onPressed: remove,
                  color: AppSemanticColors.statusError,
                  icon: const Icon(CupertinoIcons.delete),
                ),
            ],
          ),
        ),
        _timeChips(context),
        _doseRow(context),
        // The days have a focus node, so a missing day can be scrolled to.
        Focus(focusNode: data.weekdaysFocus, child: _dayChips(context)),
        InsetTextRow(
          label: context.tr('medications.dose_note'),
          hint: context.tr('medications.dose_note_hint'),
          controller: data.instructionsController,
          maxLength: 250,
          maxLines: 2,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }

  // Time ---------------------------------------------------------------

  Widget _timeChips(BuildContext context) {
    return InsetRow(
      label: context.tr('medications.time'),
      value: clockText(_code(data.time)),
      onTap: () => _selectTime(context),
    );
  }

  static String _code(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? selected = await showTafaqodTimeSheet(
      context,
      initialTime: data.time,
      title: context.tr('medications.select_time'),
    );
    if (selected == null) return;
    data.time = selected;
    onChanged();
  }

  // Dose ---------------------------------------------------------------

  /// Half a tablet and half a millilitre are common; the other units count
  /// whole capsules, drops, puffs and units.
  double get _step => switch (data.doseUnit) {
    DoseUnit.tablet || DoseUnit.milliliter => 0.5,
    _ => 1,
  };

  double? get _dose => double.tryParse(
    ArabicDigits.toWesternDecimal(data.doseController.text.trim()),
  );

  Widget _doseRow(BuildContext context) {
    final double? dose = _dose;
    final String unit = context.tr('medications.unit.${data.doseUnit.name}');
    return InsetTextRow(
      label: context.tr('medications.dose_value'),
      hint: context.tr('medications.dose_hint'),
      controller: data.doseController,
      focusNode: data.doseFocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        const WesternDigitsFormatter(decimal: true),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      errorText: issue?.field == MedicationFormField.dose
          ? context.tr('medications.positive_number')
          : null,
      onChanged: (_) => onChanged(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // One unit is a word; an injection chooses between mL and units.
          if (units.length > 1)
            InsetChoiceButton(
              label: unit,
              semanticLabel: '${context.tr('medications.dose_unit')}: $unit',
              onPressed: () => _chooseUnit(context),
            )
          else
            Text(unit, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: AppSpacing.sm),
          StepperControl(
            decrementLabel: context.tr('medications.dose_less'),
            incrementLabel: context.tr('medications.dose_more'),
            onDecrement: dose != null && dose > _step
                ? () => _stepDose(-1)
                : null,
            onIncrement: dose == null || dose < _maxDose
                ? () => _stepDose(1)
                : null,
          ),
        ],
      ),
    );
  }

  /// One step up or down, on the step's grid: 1.2 tablets goes to 1.5 or 1.
  void _stepDose(int direction) {
    final double current = _dose ?? 0;
    final double raw = current + direction * _step;
    final double snapped = (raw / _step).round() * _step;
    final double next = snapped.clamp(_step, _maxDose);
    data.doseController.text = formatMedicationNumber(next);
    onChanged();
  }

  Future<void> _chooseUnit(BuildContext context) async {
    final DoseUnit? unit = await showOptionSheet<DoseUnit>(
      context,
      title: context.tr('medications.dose_unit'),
      options: units,
      labelOf: (DoseUnit unit) => context.tr('medications.unit.${unit.name}'),
      selected: data.doseUnit,
    );
    if (unit == null) return;
    data.doseUnit = unit;
    onChanged();
  }

  // Days ---------------------------------------------------------------

  /// «أسبوعي | كل كم يوم» on the app's glass segmented control, and under
  /// it the weekdays, or the number of days on a ruler right here (not in a
  /// sheet). Apple's guidance for a segmented control is this case: two
  /// closely related views of one choice, short labels, segments of equal
  /// width.
  Widget _dayChips(BuildContext context) {
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
          if (interval) _interval(context) else _weekdays(),
        ],
      ),
    );
  }

  /// «نذكرك كل» over the number of days, large, and the ruler under it:
  /// 1 «يوم», 2 «يومين», 3 to 10 «أيام», then «يوم».
  Widget _interval(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime? start = startsOn;
    String days(int count) => arabicCount(context, ArabicCount.days, count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.tr('medications.interval_title'),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(
            color: AppSemanticColors.textSupporting,
          ),
        ),
        Text(
          days(data.intervalDays),
          textAlign: TextAlign.center,
          style: text.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        RulerPicker(
          min: 1,
          max: maxIntervalDays,
          value: data.intervalDays,
          semanticLabel: context.tr('medications.interval_days'),
          valueLabel: days,
          onChanged: (int value) {
            data.intervalDays = value;
            onChanged();
          },
        ),
        if (start != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(
              'medications.interval_from',
              args: <String>[formatMedicationDate(context, start)],
            ),
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              color: AppSemanticColors.textSupporting,
            ),
          ),
        ],
        if (data.formerMonthDays.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(
              'medications.was_monthly',
              args: <String>[formatMonthDays(context, data.formerMonthDays)],
            ),
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              color: AppSemanticColors.textSupporting,
            ),
          ),
        ],
      ],
    );
  }

  Widget _weekdays() => WeekdaySelector(
    selected: data.weekdays,
    onChanged: (Set<int> days) {
      data.weekdays
        ..clear()
        ..addAll(days);
      onChanged();
    },
  );
}
