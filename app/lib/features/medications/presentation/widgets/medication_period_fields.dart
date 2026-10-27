import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MedicationPeriodFields extends StatelessWidget {
  const MedicationPeriodFields({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;

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
        const SizedBox(height: AppSpacing.md),
        _DateField(
          label: context.tr('medications.ends_optional'),
          value: data.endsOn,
          allowClear: true,
          onChanged: (value) {
            data.endsOn = value;
            onChanged();
          },
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
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMd(context.locale.toString());
    return OutlinedButton.icon(
      onPressed: () => _select(context),
      icon: const Icon(Icons.calendar_today_outlined),
      label: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          value == null ? label : '$label: ${formatter.format(value!)}',
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context) async {
    if (allowClear && value != null) {
      final change = await showModalBottomSheet<bool>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_calendar_outlined),
                title: Text(context.tr('medications.change_date')),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: Text(context.tr('medications.no_end_date')),
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      );
      if (change == false) {
        onChanged(null);
        return;
      }
      if (change == null) return;
    }
    if (!context.mounted) return;
    final selected = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) onChanged(selected);
  }
}
