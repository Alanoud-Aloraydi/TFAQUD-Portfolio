import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/date_picker_sheet.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MedicationPeriodFields extends StatelessWidget {
  const MedicationPeriodFields({
    super.key,
    required this.data,
    required this.onChanged,
    this.issue,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;
  final MedicationFormIssue? issue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateField(
          label: context.tr('medications.starts'),
          value: data.startsOn,
          onChanged: (value) {
            if (value == null) return;
            data.startsOn = value;
            onChanged();
          },
        ),
        if (data.effectiveFromOn != null) ...[
          const SizedBox(height: AppSpacing.md),
          _DateField(
            label: context.tr('medications.effective_from'),
            value: data.effectiveFromOn,
            firstDate: DateUtils.dateOnly(
              DateTime.now().add(const Duration(days: 1)),
            ),
            onChanged: (value) {
              if (value == null) return;
              data.effectiveFromOn = value;
              onChanged();
            },
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _DateField(
          label: context.tr('medications.ends_optional'),
          value: data.endsOn,
          allowClear: true,
          focusNode: data.periodFocus,
          onChanged: (value) {
            data.endsOn = value;
            onChanged();
          },
        ),
        if (issue?.field == MedicationFormField.period)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              context.tr('medications.invalid_period'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowClear = false,
    this.firstDate,
    this.focusNode,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;
  final DateTime? firstDate;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            focusNode: focusNode,
            onPressed: () => _select(context),
            icon: const Icon(Icons.calendar_today_outlined),
            label: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value == null
                    ? label
                    : '$label: ${formatMedicationDate(context, value!)}',
              ),
            ),
          ),
        ),
        if (allowClear && value != null)
          IconButton(
            tooltip: context.tr('medications.no_end_date'),
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }

  Future<void> _select(BuildContext context) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final selected = await showTafaqodDateSheet(
      context,
      title: label,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (selected != null) onChanged(selected);
  }
}
