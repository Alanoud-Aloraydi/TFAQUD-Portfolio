import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MedicationScheduleEditor extends StatelessWidget {
  const MedicationScheduleEditor({
    super.key,
    required this.index,
    required this.data,
    required this.unit,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final ScheduleFormData data;
  final DoseUnit unit;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
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
                    label: Text(data.time.format(context)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: data.doseController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      labelText: context.tr('medications.dose_value'),
                      suffixText: context.tr('medications.unit.${unit.name}'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('medications.weekdays'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
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
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: data.time,
      helpText: context.tr('medications.select_time'),
      cancelText: context.tr('common.cancel'),
      confirmText: context.tr('common.confirm'),
    );
    if (selected == null) return;
    data.time = selected;
    onChanged();
  }
}
