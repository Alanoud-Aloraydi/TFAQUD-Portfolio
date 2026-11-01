import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The treatment period as one iOS grouped section: start, the date a change
/// applies from (when editing), and the optional end.
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
    final AppTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InsetGroup(
          header: context.tr('medications.treatment_period'),
          children: <Widget>[
            _DateRow(
              label: context.tr('medications.starts'),
              value: data.startsOn,
              onChanged: (DateTime? value) {
                if (value == null) return;
                data.startsOn = value;
                onChanged();
              },
            ),
            if (data.effectiveFromOn != null)
              _DateRow(
                label: context.tr('medications.effective_from'),
                value: data.effectiveFromOn,
                firstDate: DateUtils.dateOnly(
                  DateTime.now().add(const Duration(days: 1)),
                ),
                onChanged: (DateTime? value) {
                  if (value == null) return;
                  data.effectiveFromOn = value;
                  onChanged();
                },
              ),
            _DateRow(
              label: context.tr('medications.ends'),
              value: data.endsOn,
              placeholder: context.tr('medications.no_end_date'),
              allowClear: true,
              focusNode: data.periodFocus,
              onChanged: (DateTime? value) {
                data.endsOn = value;
                onChanged();
              },
            ),
          ],
        ),
        if (issue?.field == MedicationFormField.period)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              end: AppSpacing.lg,
              top: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: AppSizes.iconSmall,
                  color: tokens.error,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.tr('medications.invalid_period'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: tokens.errorText),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.allowClear = false,
    this.firstDate,
    this.focusNode,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? placeholder;
  final bool allowClear;
  final DateTime? firstDate;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final DateTime? date = value;
    return InsetRow(
      label: label,
      value: date == null ? null : formatMedicationDate(context, date),
      placeholder: placeholder,
      focusNode: focusNode,
      onTap: () => _select(context),
      trailing: allowClear && date != null
          ? IconButton(
              tooltip: context.tr('medications.no_end_date'),
              onPressed: () => onChanged(null),
              icon: const Icon(
                CupertinoIcons.xmark_circle,
                size: AppSizes.iconSmall,
              ),
            )
          : null,
      showChevron: !(allowClear && date != null),
    );
  }

  Future<void> _select(BuildContext context) async {
    final DateTime now = DateUtils.dateOnly(DateTime.now());
    final DateTime? selected = await showTafaqodDateSheet(
      context,
      title: label,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (selected != null) onChanged(selected);
  }
}
