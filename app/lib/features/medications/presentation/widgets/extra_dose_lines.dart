import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/fact_pill.dart';
import 'package:app/features/medications/domain/entities/dose_history_entry.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/cubit/schedule_form_defaults.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_earlier.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_form.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The words of an extra dose in the history, as a dose of a dose time
/// has them: the time it was taken right above the medicine, whose
/// strength and dose sit beside its name in small pills.
class ExtraDoseLines extends StatelessWidget {
  const ExtraDoseLines({super.key, required this.entry});

  final ExtraDoseEntry entry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      DoseHistoryHeading.taken(takenAt: entry.dose.takenAt),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            entry.medicine.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          FactPill(
            strengthText(
              context,
              entry.medicine.strengthValue,
              entry.medicine.strengthUnit,
            ),
          ),
          FactPill(
            formatMedicationDose(
              context,
              entry.dose.doseValue,
              entry.dose.doseUnit,
            ),
          ),
        ],
      ),
    ],
  );
}

/// What [ExtraDoseForm] holds: the medicine chosen (the only one when there
/// is one), the dose typed, the time picked (now until then), and whether
/// save was tapped with something missing.
mixin ExtraDoseFormScope on State<ExtraDoseForm> {
  late MedicationPlan? plan = widget.plans.length == 1
      ? widget.plans.single
      : null;
  late final ScheduleFormData dose = newScheduleForm(doseUnit: unitOf(plan));
  TimeOfDay? picked;
  bool showErrors = false;

  static DoseUnit unitOf(MedicationPlan? plan) =>
      plan?.version.dosageForm.defaultDoseUnit ?? DoseUnit.tablet;

  @override
  void dispose() {
    dose.dispose();
    super.dispose();
  }

  /// A dose above zero, as the server keeps it; null otherwise.
  double? get doseValue {
    final double? value = typedDose(dose.doseController.text);
    return value == null || value <= 0 || value > maxDose ? null : value;
  }

  /// A change in the sheet: the last error no longer applies.
  void changed(VoidCallback change) {
    setState(change);
    context.read<ExtraDoseCubit>().clearError();
  }
}
