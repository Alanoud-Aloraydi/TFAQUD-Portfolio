import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The treatment start and optional end in one grouped section.
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
            InsetBlock(
              semanticLabel: context.tr('medications.duration'),
              child: OptionChips(
                options: <ChipOption>[
                  ChipOption(
                    'continuous',
                    context.tr('medications.continuous'),
                  ),
                  ChipOption('dated', context.tr('medications.until_date')),
                ],
                isSelected: (String code) => code == 'continuous'
                    ? data.endsOn == null
                    : data.endsOn != null,
                onTap: (String code) async {
                  if (code == 'continuous') {
                    data.endsOn = null;
                    onChanged();
                    return;
                  }
                  final first = data.effectiveFromOn ?? data.startsOn;
                  final selected = await showTafaqodDateSheet(
                    context,
                    title: context.tr('medications.ends'),
                    initialDate: data.endsOn ?? first,
                    firstDate: first,
                    lastDate: first.add(const Duration(days: 3650)),
                  );
                  if (selected == null) return;
                  data.endsOn = selected;
                  onChanged();
                },
              ),
            ),
            _DateRow(
              label: context.tr('medications.starts'),
              value: data.startsOn,
              firstDate: data.effectiveFromOn == null ? riyadhToday() : null,
              onChanged: (DateTime? value) {
                if (value == null) return;
                data.startsOn = value;
                onChanged();
              },
            ),
            if (data.endsOn != null)
              _DateRow(
                label: context.tr('medications.ends'),
                value: data.endsOn,
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
                  AppIcons.warningCircle,
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

/// A revision starts on the next day or a later selected day.
class MedicationEffectiveDateGroup extends StatelessWidget {
  const MedicationEffectiveDateGroup({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final tomorrow = riyadhToday().add(const Duration(days: 1));
    final selected = data.effectiveFromOn ?? tomorrow;
    final isTomorrow = DateUtils.isSameDay(selected, tomorrow);
    return InsetGroup(
      header: context.tr('medications.effective_question'),
      footer: context.tr('medications.effective_hint'),
      children: <Widget>[
        InsetBlock(
          semanticLabel: context.tr('medications.effective_question'),
          child: OptionChips(
            options: <ChipOption>[
              ChipOption('tomorrow', context.tr('medications.tomorrow')),
              ChipOption('date', context.tr('medications.specific_date')),
            ],
            isSelected: (String code) =>
                code == 'tomorrow' ? isTomorrow : !isTomorrow,
            onTap: (String code) {
              if (code == 'tomorrow') {
                data.effectiveFromOn = tomorrow;
                onChanged();
              } else {
                _chooseDate(context, tomorrow, selected);
              }
            },
          ),
        ),
        if (!isTomorrow)
          _DateRow(
            label: context.tr('medications.effective_from'),
            value: selected,
            firstDate: tomorrow,
            onChanged: (DateTime? date) {
              if (date == null) return;
              data.effectiveFromOn = date;
              onChanged();
            },
          ),
      ],
    );
  }

  Future<void> _chooseDate(
    BuildContext context,
    DateTime tomorrow,
    DateTime selected,
  ) async {
    final date = await showTafaqodDateSheet(
      context,
      title: context.tr('medications.effective_from'),
      initialDate: selected,
      firstDate: tomorrow,
      lastDate: tomorrow.add(const Duration(days: 3650)),
    );
    if (date == null) return;
    data.effectiveFromOn = date;
    onChanged();
  }
}

/// Renders the date row element of medication period fields.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.focusNode,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final DateTime? date = value;
    return InsetRow(
      label: label,
      value: date == null ? null : formatMedicationDate(context, date),
      focusNode: focusNode,
      onTap: () => _select(context),
      showChevron: true,
    );
  }

  Future<void> _select(BuildContext context) async {
    final DateTime now = riyadhToday();
    final DateTime? selected = await showTafaqodDateSheet(
      context,
      title: label,
      initialDate:
          value != null && firstDate != null && value!.isBefore(firstDate!)
          ? firstDate!
          : value ?? now,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (selected != null) onChanged(selected);
  }
}
