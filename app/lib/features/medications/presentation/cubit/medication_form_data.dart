import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/cubit/schedule_form_defaults.dart';
import 'package:flutter/material.dart';

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

/// What the form refuses, and which field to open at.
extension MedicationFormValidation on MedicationFormData {
  /// The first field that is not filled in, in the order the form reads;
  /// null when the whole form can be saved.
  MedicationFormIssue? firstIssue() {
    if (name.text.trim().isEmpty) {
      return const MedicationFormIssue(MedicationFormField.name);
    }
    final strengthText = ArabicDigits.toWesternDecimal(strength.text.trim());
    final strengthValue = isDecimalText(strengthText)
        ? double.tryParse(strengthText)
        : null;
    if (strengthValue == null || strengthValue <= 0) {
      return const MedicationFormIssue(MedicationFormField.strength);
    }
    if ((endsOn != null && endsOn!.isBefore(startsOn)) ||
        (endsOn != null &&
            effectiveFromOn != null &&
            endsOn!.isBefore(effectiveFromOn!))) {
      return const MedicationFormIssue(MedicationFormField.period);
    }
    for (var index = 0; index < schedules.length; index++) {
      final schedule = schedules[index];
      final doseText = ArabicDigits.toWesternDecimal(
        schedule.doseController.text.trim(),
      );
      final dose = isDecimalText(doseText) ? double.tryParse(doseText) : null;
      if (dose == null || dose <= 0) {
        return MedicationFormIssue(
          MedicationFormField.dose,
          scheduleIndex: index,
        );
      }
      if (!schedule.hasDays) {
        return MedicationFormIssue(
          MedicationFormField.weekdays,
          scheduleIndex: index,
        );
      }
    }
    if (!PlanLimits.isValidMissedAfter(missedAfterMinutes)) {
      return const MedicationFormIssue(MedicationFormField.missedAfter);
    }
    return null;
  }
}

/// What the form sends to the server.
extension MedicationFormDraft on MedicationFormData {
  /// The medicine as typed, or null while the form still refuses something.
  MedicationPlanDraft? toDraft() {
    if (firstIssue() != null) return null;
    final strengthText = ArabicDigits.toWesternDecimal(strength.text.trim());
    return MedicationPlanDraft(
      name: name.text.trim(),
      strengthValue: double.parse(strengthText),
      strengthUnit: strengthUnit,
      dosageForm: form,
      reason: optionalText(reason.text),
      instructions: optionalText(instructions.text),
      missedAfterMinutes: missedAfterMinutes!,
      startsOn: startsOn,
      endsOn: endsOn,
      effectiveFromOn: effectiveFromOn,
      schedules: <MedicationScheduleDraft>[
        for (final item in schedules) _scheduleDraft(item),
      ],
    );
  }

  MedicationScheduleDraft _scheduleDraft(ScheduleFormData item) {
    final doseText = ArabicDigits.toWesternDecimal(
      item.doseController.text.trim(),
    );
    return MedicationScheduleDraft(
      time: formTimeText(item.time),
      doseValue: double.parse(doseText),
      doseUnit: item.doseUnit,
      repeat: item.repeat,
      weekdays: item.repeat == ScheduleRepeat.weekly
          ? (item.weekdays.toList()..sort())
          : const <int>[],
      intervalDays: item.repeat == ScheduleRepeat.interval
          ? item.intervalDays
          : null,
      instructions: optionalText(item.instructionsController.text),
    );
  }
}
