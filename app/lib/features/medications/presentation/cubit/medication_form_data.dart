import 'package:app/core/constants/plan_limits.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/cubit/schedule_form_defaults.dart';
import 'package:flutter/material.dart';

export 'package:app/features/medications/presentation/cubit/medication_form_validation.dart';
export 'package:app/features/medications/presentation/cubit/medication_schedule_form_data.dart';

/// Holds medication form values for this workflow.
class MedicationFormData {
  /// Filled from [plan]'s latest version: a change waiting for later, when
  /// there is one, so editing again starts from it. [today] is the
  /// patient's, where a new medicine and an edit start.
  MedicationFormData(MedicationPlan? plan, {required DateTime today})
    : this._(plan?.pendingVersion ?? plan?.version, today);

  MedicationFormData._(MedicationVersion? version, DateTime today)
    : name = TextEditingController(text: version?.name),
      strength = TextEditingController(
        text: version == null ? null : formNumberText(version.strengthValue),
      ),
      strengthUnit = version?.strengthUnit ?? StrengthUnit.milligram,
      reason = TextEditingController(text: version?.reason),
      instructions = TextEditingController(text: version?.instructions),
      form = version?.dosageForm ?? DosageForm.tablet,
      missedAfterMinutes =
          version?.missedAfterMinutes ?? PlanLimits.defaultMissedAfterMinutes,
      startsOn = version?.startsOn ?? today,
      endsOn = version?.endsOn,
      effectiveFromOn = version == null ? null : today,
      // A new medicine starts with no dose time: one taken when needed
      // keeps none, and its doses go through «سجّل جرعة الآن».
      schedules = version == null
          ? <ScheduleFormData>[]
          : version.schedules.map(scheduleFormOf).toList();

  final TextEditingController name;
  final TextEditingController strength;
  StrengthUnit strengthUnit;
  final TextEditingController reason;
  final TextEditingController instructions;

  /// Whether «أخرى» is chosen among the instructions, so their text field
  /// shows, even while it is still empty. Instructions of their own words
  /// already saved count as «أخرى» too.
  bool otherInstructions = false;
  final FocusNode nameFocus = FocusNode();
  final FocusNode strengthFocus = FocusNode();
  final FocusNode periodFocus = FocusNode();
  final FocusNode missedAfterFocus = FocusNode();
  DosageForm form;
  int? missedAfterMinutes;
  DateTime startsOn;
  DateTime? endsOn;
  DateTime? effectiveFromOn;
  final List<ScheduleFormData> schedules;
}

/// Letting go of the form's controllers and focus nodes.
extension MedicationFormDispose on MedicationFormData {
  void dispose() {
    name.dispose();
    strength.dispose();
    reason.dispose();
    instructions.dispose();
    nameFocus.dispose();
    strengthFocus.dispose();
    periodFocus.dispose();
    missedAfterFocus.dispose();
    for (final schedule in schedules) {
      schedule.dispose();
    }
  }
}

/// Adding and removing dose times while the form is open.
extension MedicationFormSchedules on MedicationFormData {
  /// A new dose time keeps the unit of the one before it, when that unit
  /// belongs to the form chosen.
  void addSchedule() {
    final previousUnit = schedules.isEmpty ? null : schedules.last.doseUnit;
    final unit = form.doseUnits.contains(previousUnit)
        ? previousUnit!
        : form.defaultDoseUnit;
    schedules.add(newScheduleForm(doseUnit: unit));
  }

  void removeSchedule(int index) => schedules.removeAt(index).dispose();
}

/// Describes one medication form validation issue.
class MedicationFormIssue {
  const MedicationFormIssue(this.field, {this.scheduleIndex});

  final MedicationFormField field;
  final int? scheduleIndex;
}
