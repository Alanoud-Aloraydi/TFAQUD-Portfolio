import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_date_row.dart';
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
            MedicationDateRow(
              label: context.tr('medications.starts'),
              value: data.startsOn,
              firstDate: data.effectiveFromOn == null
                  ? PatientClockScope.of(context).today()
                  : null,
              onChanged: (DateTime? value) {
                if (value == null) return;
                data.startsOn = value;
                onChanged();
              },
            ),
            if (data.endsOn != null)
              MedicationDateRow(
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
