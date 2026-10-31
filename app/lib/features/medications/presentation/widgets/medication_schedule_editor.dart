import 'package:app/core/widgets/inset_group.dart';
import 'package:app/core/widgets/time_picker_sheet.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One dose time as an iOS grouped section: time, amount, unit, weekdays and
/// the instructions for this dose. The header names the dose and holds its
/// delete button.
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
              icon: const Icon(Icons.delete_outline),
            ),
      children: <Widget>[
        InsetRow(
          label: context.tr('medications.time'),
          value: formatMedicationTime(
            context,
            '${data.time.hour.toString().padLeft(2, '0')}:'
            '${data.time.minute.toString().padLeft(2, '0')}',
          ),
          showChevron: true,
          onTap: () => _selectTime(context),
        ),
        InsetTextRow(
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
        ),
        InsetRow(
          label: context.tr('medications.dose_unit'),
          value: context.tr('medications.unit.${data.doseUnit.name}'),
          showChevron: true,
          onTap: () => _chooseUnit(context),
        ),
        // The days, as Apple Health asks them: one row with a summary that
        // opens a list with check marks.
        Focus(
          focusNode: data.weekdaysFocus,
          child: InsetRow(
            label: context.tr('medications.repeat'),
            value: _daysSummary(context),
            showChevron: true,
            onTap: () => _chooseDays(context),
            errorText: issue?.field == MedicationFormField.weekdays
                ? context.tr('medications.weekday_required')
                : null,
          ),
        ),
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

  /// The week as it is read in Saudi Arabia: Sunday first. The numbers are
  /// those of [DateTime.weekday] (Monday 1 … Sunday 7).
  static const List<int> _weekOrder = <int>[7, 1, 2, 3, 4, 5, 6];

  /// «كل يوم», or the chosen days in week order: «الأحد، الأربعاء».
  /// Null (an empty row) when no day is chosen; the row then shows an error.
  String? _daysSummary(BuildContext context) {
    if (data.weekdays.length == 7) return context.tr('medications.every_day');
    if (data.weekdays.isEmpty) return null;
    return <String>[
      for (final int day in _weekOrder)
        if (data.weekdays.contains(day)) context.tr('medications.weekday.$day'),
    ].join('، ');
  }

  Future<void> _chooseDays(BuildContext context) async {
    final Set<int>? days = await showChecklistSheet<int>(
      context,
      title: context.tr('medications.repeat'),
      options: _weekOrder,
      labelOf: (int day) => context.tr('medications.weekday.$day'),
      selected: data.weekdays,
    );
    if (days == null) return;
    data.weekdays
      ..clear()
      ..addAll(days);
    onChanged();
  }

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
}
