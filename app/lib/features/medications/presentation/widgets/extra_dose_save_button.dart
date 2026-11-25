import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «حفظ الجرعة», off while the dose is on its way, with why the last try
/// was not saved above it.
class ExtraDoseSaveButton extends StatelessWidget {
  const ExtraDoseSaveButton({
    super.key,
    required this.onPressed,
    this.missingKey,
  });

  final VoidCallback onPressed;

  /// What is missing in the sheet itself: a key in assets/translations.
  final String? missingKey;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ExtraDoseCubit, ExtraDoseState>(
        builder: (BuildContext context, ExtraDoseState state) {
          final String? errorKey = missingKey ?? state.errorKey;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (errorKey != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                InlineError(messageKey: errorKey),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: state.saving ? null : onPressed,
                child: Text(context.tr('medications.dose_now_save')),
              ),
            ],
          );
        },
      );
}

/// «كمية الجرعة» of «سجّل جرعة الآن», in the units [plan]'s form is taken
/// in.
class ExtraDoseAmountGroup extends StatelessWidget {
  const ExtraDoseAmountGroup({
    super.key,
    required this.plan,
    required this.dose,
    required this.onChanged,
    required this.showError,
  });

  final MedicationPlan plan;
  final ScheduleFormData dose;
  final VoidCallback onChanged;

  /// Save was tapped while the dose is not a number above zero.
  final bool showError;

  @override
  Widget build(BuildContext context) => InsetGroup(
    children: <Widget>[
      MedicationDoseRow(
        data: dose,
        units: plan.version.dosageForm.doseUnits,
        onChanged: onChanged,
        issue: showError
            ? const MedicationFormIssue(MedicationFormField.dose)
            : null,
      ),
    ],
  );
}
