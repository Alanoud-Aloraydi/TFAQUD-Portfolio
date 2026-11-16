import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:flutter/material.dart';

/// Opens the keyboard on the field the form refused and scrolls it into
/// view, so the person sees what is being asked of them.
Future<void> focusMedicationIssue(
  MedicationFormData data,
  MedicationFormIssue issue,
) async {
  final FocusNode node = switch (issue.field) {
    MedicationFormField.name => data.nameFocus,
    MedicationFormField.strength => data.strengthFocus,
    MedicationFormField.period => data.periodFocus,
    MedicationFormField.missedAfter => data.missedAfterFocus,
    MedicationFormField.dose => data.schedules[issue.scheduleIndex!].doseFocus,
    MedicationFormField.weekdays =>
      data.schedules[issue.scheduleIndex!].weekdaysFocus,
  };
  node.requestFocus();
  final BuildContext? fieldContext = node.context;
  if (fieldContext != null) {
    await Scrollable.ensureVisible(
      fieldContext,
      duration: AppMotion.formScroll,
    );
  }
}
