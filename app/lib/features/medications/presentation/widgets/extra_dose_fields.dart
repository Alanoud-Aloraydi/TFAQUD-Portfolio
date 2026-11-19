import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_amount_group.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_medicines.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_save_button.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_time_group.dart';
import 'package:flutter/material.dart';

/// «سجّل جرعة الآن» laid out: the medicines, then, once one is chosen,
/// how much and when, then the save button.
class ExtraDoseFields extends StatelessWidget {
  const ExtraDoseFields({
    super.key,
    required this.circleId,
    required this.plans,
    required this.plan,
    required this.dose,
    required this.time,
    required this.doseError,
    required this.missingKey,
    required this.onChoose,
    required this.onDoseChanged,
    required this.onTimePicked,
    required this.onSave,
  });

  final String circleId;
  final List<MedicationPlan> plans;
  final MedicationPlan? plan;
  final ScheduleFormData dose;
  final TimeOfDay time;
  final bool doseError;

  /// What stops the save in the sheet itself: a key in assets/translations.
  final String? missingKey;
  final ValueChanged<MedicationPlan> onChoose;
  final VoidCallback onDoseChanged;
  final ValueChanged<TimeOfDay> onTimePicked;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final MedicationPlan? chosen = plan;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExtraDoseMedicines(
          circleId: circleId,
          plans: plans,
          chosenId: chosen?.id,
          onChoose: onChoose,
        ),
        if (chosen != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          ExtraDoseAmountGroup(
            plan: chosen,
            dose: dose,
            onChanged: onDoseChanged,
            showError: doseError,
          ),
          const SizedBox(height: AppSpacing.lg),
          ExtraDoseTimeGroup(time: time, onPicked: onTimePicked),
        ],
        ExtraDoseSaveButton(onPressed: onSave, missingKey: missingKey),
      ],
    );
  }
}
