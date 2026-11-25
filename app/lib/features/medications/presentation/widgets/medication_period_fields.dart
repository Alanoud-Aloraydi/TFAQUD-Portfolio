import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_wheel_choice.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_date_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The treatment start and optional end in one grouped section. A start in
/// the past ([startError]) is said under the start.
class MedicationPeriodFields extends StatelessWidget {
  const MedicationPeriodFields({
    super.key,
    required this.data,
    required this.onChanged,
    this.issue,
    this.startError,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;
  final MedicationFormIssue? issue;

  /// The translation key of the start's refusal, or null.
  final String? startError;

  @override
  Widget build(BuildContext context) {
    final String? start = startError == null ? null : context.tr(startError!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FieldWithError.reveal(
          error: start,
          child: InsetGroup(
            header: context.tr('medications.treatment_period'),
            children: <Widget>[
              MedicationDurationChips(data: data, onChanged: onChanged),
              MedicationStartRow(
                data: data,
                error: start,
                onChanged: onChanged,
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
        ),
        if (issue?.field == MedicationFormField.period)
          const MedicationIssueNote(messageKey: 'medications.invalid_period'),
      ],
    );
  }
}

/// «يبدأ» of a treatment: its first day, from the patient's today for a new
/// plan, and the start's refusal ([error]) under it.
class MedicationStartRow extends StatelessWidget {
  const MedicationStartRow({
    super.key,
    required this.data,
    required this.onChanged,
    this.error,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;

  /// The start's refusal, translated, or null.
  final String? error;

  @override
  Widget build(BuildContext context) => MedicationDateRow(
    label: context.tr('medications.starts'),
    value: data.startsOn,
    errorText: error,
    firstDate: data.effectiveFromOn == null
        ? PatientClockScope.of(context).today()
        : null,
    onChanged: (DateTime? value) {
      if (value == null) return;
      data.startsOn = value;
      onChanged();
    },
  );
}

/// «مستمر | حتى تاريخ»: choosing a date opens the date sheet at once, and
/// «مستمر» clears the end again.
class MedicationDurationChips extends StatelessWidget {
  const MedicationDurationChips({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InsetBlock(
      semanticLabel: context.tr('medications.duration'),
      child: OptionChips(
        options: <ChipOption>[
          ChipOption('continuous', context.tr('medications.continuous')),
          ChipOption('dated', context.tr('medications.until_date')),
        ],
        isSelected: (String code) =>
            code == 'continuous' ? data.endsOn == null : data.endsOn != null,
        onTap: (String code) => _choose(context, code),
      ),
    );
  }

  Future<void> _choose(BuildContext context, String code) async {
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
  }
}

/// What a field of the medicine's form refused, under the group it belongs
/// to: the warning sign and [messageKey] in the error colour.
class MedicationIssueNote extends StatelessWidget {
  const MedicationIssueNote({super.key, required this.messageKey});

  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.lg,
        top: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            NoticeIcons.warningCircle,
            size: AppSizes.iconSmall,
            color: tokens.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.tr(messageKey),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: tokens.errorText),
            ),
          ),
        ],
      ),
    );
  }
}
