import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/time_picker_sheet.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(
                      'medications.schedule_number',
                      args: [(index + 1).toString()],
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: context.tr('medications.remove_schedule'),
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context),
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(
                      formatMedicationTime(
                        context,
                        '${data.time.hour.toString().padLeft(2, '0')}:'
                        '${data.time.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    focusNode: data.doseFocus,
                    controller: data.doseController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      labelText: context.tr('medications.dose_value'),
                      errorText: issue?.field == MedicationFormField.dose
                          ? context.tr('medications.positive_number')
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<DoseUnit>(
              initialValue: data.doseUnit,
              decoration: InputDecoration(
                labelText: context.tr('medications.dose_unit'),
              ),
              items: [
                for (final unit in units)
                  DropdownMenuItem(
                    value: unit,
                    child: Text(context.tr('medications.unit.${unit.name}')),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                data.doseUnit = value;
                onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('medications.weekdays'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Focus(
              focusNode: data.weekdaysFocus,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(context.tr('medications.weekday.$day')),
                    selected: data.weekdays.contains(day),
                    onSelected: (selected) {
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
            if (issue?.field == MedicationFormField.weekdays)
              Text(
                context.tr('medications.weekday_required'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: data.instructionsController,
          maxLength: 250,
          maxLines: 2,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: context.tr('medications.schedule_instructions'),
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final selected = await showTafaqodTimeSheet(
      context,
      initialTime: data.time,
      title: context.tr('medications.select_time'),
    );
    if (selected == null) return;
    data.time = selected;
    onChanged();
  }
}
