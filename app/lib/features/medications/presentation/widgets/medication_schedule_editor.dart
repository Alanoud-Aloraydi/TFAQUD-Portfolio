import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/inset_group.dart';
import 'package:app/core/widgets/option_chips.dart';
import 'package:app/core/widgets/stepper_control.dart';
import 'package:app/core/widgets/time_picker_sheet.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One dose time as an iOS grouped section. The choices are on the screen,
/// one tap away, as a booking app shows them instead of empty fields:
///
/// * the time as chips of the usual times, and «وقت آخر» for the wheel;
/// * the dose as a number with its unit and the iOS stepper (− +), and the
///   number can still be typed;
/// * the days as chips, with «كل يوم» first;
/// * the instructions for this dose.
///
/// The header names the dose and holds its delete button.
class MedicationScheduleEditor extends StatelessWidget {
  const MedicationScheduleEditor({
    super.key,
    required this.index,
    required this.data,
    required this.units,
    required this.onChanged,
    this.onRemove,
    this.issue,
  });

  final int index;
  final ScheduleFormData data;
  final List<DoseUnit> units;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  final MedicationFormIssue? issue;

  /// The usual dose times: morning, afternoon and evening.
  static const List<TimeOfDay> _usualTimes = <TimeOfDay>[
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 20, minute: 0),
  ];

  static const String _otherTime = 'other';
  static const String _everyDay = 'every';

  /// The week as it is read in Saudi Arabia: Sunday first. The numbers are
  /// those of [DateTime.weekday] (Monday 1 … Sunday 7).
  static const List<int> _weekOrder = <int>[7, 1, 2, 3, 4, 5, 6];

  /// The largest dose the stepper reaches.
  static const double _maxDose = 999;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? remove = onRemove;
    return InsetGroup(
      header: context.tr(
        'medications.schedule_number',
        args: <String>[(index + 1).toString()],
      ),
      headerAction: remove == null
          ? null
          : IconButton(
              tooltip: context.tr('medications.remove_schedule'),
              onPressed: remove,
              color: AppColors.error,
              icon: const Icon(CupertinoIcons.delete),
            ),
      children: <Widget>[
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
    final bool usual = _usualTimes.contains(data.time);
    return InsetBlock(
      semanticLabel: context.tr('medications.time'),
      child: OptionChips(
        options: <ChipOption>[
          for (final TimeOfDay time in _usualTimes)
            ChipOption(_code(time), formatMedicationTime(context, _code(time))),
          // Another time shows itself once chosen, so the chosen time is
          // always on the screen.
          ChipOption(
            _otherTime,
            usual
                ? context.tr('medications.other_time')
                : formatMedicationTime(context, _code(data.time)),
          ),
        ],
        isSelected: (String code) =>
            code == _otherTime ? !usual : code == _code(data.time),
        onTap: (String code) {
          if (code == _otherTime) {
            _selectTime(context);
            return;
          }
          data.time = _usualTimes.firstWhere((TimeOfDay t) => _code(t) == code);
          onChanged();
        },
      ),
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

  double? get _dose => double.tryParse(data.doseController.text.trim());

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
            onDecrement: dose != null && dose > _step ? () => _stepDose(-1) : null,
            onIncrement: dose == null || dose < _maxDose ? () => _stepDose(1) : null,
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

  Widget _dayChips(BuildContext context) {
    final bool everyDay = data.weekdays.length == _weekOrder.length;
    return InsetBlock(
      semanticLabel: context.tr('medications.repeat'),
      errorText: issue?.field == MedicationFormField.weekdays
          ? context.tr('medications.weekday_required')
          : null,
      child: OptionChips(
        options: <ChipOption>[
          ChipOption(_everyDay, context.tr('medications.every_day')),
          for (final int day in _weekOrder)
            ChipOption('$day', context.tr('medications.weekday.$day')),
        ],
        isSelected: (String code) =>
            code == _everyDay ? everyDay : data.weekdays.contains(int.parse(code)),
        onTap: (String code) {
          if (code == _everyDay) {
            // «كل يوم» chooses the whole week; tapped again, it clears it.
            if (everyDay) {
              data.weekdays.clear();
            } else {
              data.weekdays.addAll(_weekOrder);
            }
          } else {
            final int day = int.parse(code);
            if (!data.weekdays.remove(day)) data.weekdays.add(day);
          }
          onChanged();
        },
      ),
    );
  }
}
