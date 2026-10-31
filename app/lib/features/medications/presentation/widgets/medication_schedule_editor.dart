import 'package:app/core/theme/app_tokens.dart';
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
    final AppTokens tokens = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
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
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(context.tr('medications.weekdays'), style: text.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Focus(
                focusNode: data.weekdaysFocus,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (int day = 1; day <= 7; day++)
                      FilterChip(
                        label: Text(context.tr('medications.weekday.$day')),
                        selected: data.weekdays.contains(day),
                        onSelected: (bool selected) {
                          if (selected) {
                            data.weekdays.add(day);
                          } else {
                            data.weekdays.remove(day);
                          }
                          onChanged();
                        },
                      ),
                  ],
                ),
              ),
              if (issue?.field == MedicationFormField.weekdays) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.error_outline, size: 18, color: tokens.error),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        context.tr('medications.weekday_required'),
                        style: text.bodySmall?.copyWith(color: tokens.errorText),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        InsetTextRow(
          label: context.tr('medications.schedule_instructions'),
          controller: data.instructionsController,
          maxLength: 250,
          maxLines: 2,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
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
