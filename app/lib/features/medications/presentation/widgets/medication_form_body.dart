import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/features/medications/presentation/widgets/medication_effective_date_group.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_medicine.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_instructions_group.dart';
import 'package:app/features/medications/presentation/widgets/medication_period_fields.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedules_group.dart';
import 'package:flutter/material.dart';

/// What the form asks for, top to bottom: the medicine itself with its
/// photo, its dose times, the day a change takes over, the instructions,
/// and the treatment period.
class MedicationFormBody extends StatelessWidget {
  const MedicationFormBody({super.key, required this.state});

  final MedicationFormState state;

  @override
  Widget build(BuildContext context) {
    final bool startInPast = state.errorKey == 'medications.start_in_past';
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MedicationFormMedicine(state: state),
          const SizedBox(height: AppSpacing.xl),
          MedicationSchedulesGroup(state: state),
          if (state.widget.plan != null && state.medicalFieldsDirty) ...[
            const SizedBox(height: AppSpacing.xl),
            MedicationEffectiveDateGroup(
              data: state.data,
              circleId: state.widget.circleId,
              onChanged: state.changed,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          MedicationInstructionsGroup(
            data: state.data,
            issue: state.issue,
            onChanged: state.changed,
          ),
          const SizedBox(height: AppSpacing.xl),
          MedicationPeriodFields(
            data: state.data,
            issue: state.issue,
            onChanged: state.changed,
            startError: startInPast ? state.errorKey : null,
          ),
          MedicationFormFooter(errorKey: startInPast ? null : state.errorKey),
        ],
      ),
    );
  }
}

/// The end of the medication form. Why it could not be saved ([errorKey])
/// is a toast: a refusal of a field is said under that field. Stopping a
/// medicine is not here: it is in the medicine's details on its card, with
/// the stop of a measurement plan and the cancel of a visit.
class MedicationFormFooter extends StatelessWidget {
  const MedicationFormFooter({super.key, this.errorKey});

  final String? errorKey;

  @override
  Widget build(BuildContext context) => ErrorToast(
    errorKey: errorKey,
    child: const SizedBox(height: AppSpacing.xl),
  );
}
