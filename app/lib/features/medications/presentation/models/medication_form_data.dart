import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:flutter/material.dart';

/// Defines the supported medication form field values.
enum MedicationFormField { name, strength, period, dose, weekdays }

/// Describes one medication form validation issue.
class MedicationFormIssue {
  const MedicationFormIssue(this.field, {this.scheduleIndex});

  final MedicationFormField field;
  final int? scheduleIndex;
}

/// Holds medication form values for this workflow.
class MedicationFormData {
  MedicationFormData(MedicationPlan? plan)
    : name = TextEditingController(text: plan?.version.name),
      strength = TextEditingController(
        text: plan == null ? null : _number(plan.version.strengthValue),
      ),
      strengthUnit = plan?.version.strengthUnit ?? StrengthUnit.milligram,
      reason = TextEditingController(text: plan?.version.reason),
      instructions = TextEditingController(text: plan?.version.instructions),
      form = plan?.version.dosageForm ?? DosageForm.tablet,
      missedAfterMinutes = plan?.version.missedAfterMinutes ?? 60,
      startsOn = plan?.version.startsOn ?? riyadhToday(),
      endsOn = plan?.version.endsOn,
      effectiveFromOn = plan == null ? null : riyadhToday(),
      schedules = plan == null
          ? [_newSchedule()]
          : plan.version.schedules.map(_fromSchedule).toList();

  final TextEditingController name;
  final TextEditingController strength;
  StrengthUnit strengthUnit;
  final TextEditingController reason;
  final TextEditingController instructions;
  final FocusNode nameFocus = FocusNode();
  final FocusNode strengthFocus = FocusNode();
  final FocusNode periodFocus = FocusNode();
  DosageForm form;
  int missedAfterMinutes;
  DateTime startsOn;
  DateTime? endsOn;
  DateTime? effectiveFromOn;
  final List<ScheduleFormData> schedules;

  void addSchedule() {
    final previousUnit = schedules.isEmpty ? null : schedules.last.doseUnit;
    final unit = form.doseUnits.contains(previousUnit)
        ? previousUnit!
        : form.defaultDoseUnit;
    schedules.add(_newSchedule(doseUnit: unit));
  }

  void removeSchedule(int index) => schedules.removeAt(index).dispose();

  MedicationFormIssue? firstIssue() {
    if (name.text.trim().isEmpty) {
      return const MedicationFormIssue(MedicationFormField.name);
    }
    final strengthText = ArabicDigits.toWesternDecimal(strength.text.trim());
    final strengthValue = _decimal(strengthText)
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
      final dose = _decimal(doseText) ? double.tryParse(doseText) : null;
      if (dose == null || dose <= 0) {
        return MedicationFormIssue(
          MedicationFormField.dose,
          scheduleIndex: index,
        );
      }
      if (schedule.chosenDays.isEmpty) {
        return MedicationFormIssue(
          MedicationFormField.weekdays,
          scheduleIndex: index,
        );
      }
    }
    return null;
  }

  MedicationPlanDraft? toDraft() {
    if (firstIssue() != null) return null;
    final strengthText = ArabicDigits.toWesternDecimal(strength.text.trim());
    final strengthValue = double.parse(strengthText);
    final scheduleDrafts = <MedicationScheduleDraft>[];
    for (final item in schedules) {
      final doseText = ArabicDigits.toWesternDecimal(
        item.doseController.text.trim(),
      );
      final dose = double.parse(doseText);
      scheduleDrafts.add(
        MedicationScheduleDraft(
          time: _time(item.time),
          doseValue: dose,
          doseUnit: item.doseUnit,
          repeat: item.repeat,
          weekdays: item.repeat == ScheduleRepeat.weekly
              ? (item.weekdays.toList()..sort())
              : const <int>[],
          monthDays: item.repeat == ScheduleRepeat.monthly
              ? (item.monthDays.toList()..sort())
              : const <int>[],
          instructions: _optional(item.instructionsController.text),
        ),
      );
    }
    return MedicationPlanDraft(
      name: name.text.trim(),
      strengthValue: strengthValue,
      strengthUnit: strengthUnit,
      dosageForm: form,
      reason: _optional(reason.text),
      instructions: _optional(instructions.text),
      missedAfterMinutes: missedAfterMinutes,
      startsOn: startsOn,
      endsOn: endsOn,
      effectiveFromOn: effectiveFromOn,
      schedules: scheduleDrafts,
    );
  }

  void dispose() {
    name.dispose();
    strength.dispose();
    reason.dispose();
    instructions.dispose();
    nameFocus.dispose();
    strengthFocus.dispose();
    periodFocus.dispose();
    for (final schedule in schedules) {
      schedule.dispose();
    }
  }

  // A new dose starts on the most common answer (one tablet at 8:00, every
  // day), so most people only check it.
  static ScheduleFormData _newSchedule({DoseUnit doseUnit = DoseUnit.tablet}) =>
      ScheduleFormData(
        time: const TimeOfDay(hour: 8, minute: 0),
        dose: 1,
        doseUnit: doseUnit,
        weekdays: {1, 2, 3, 4, 5, 6, 7},
      );

  static ScheduleFormData _fromSchedule(MedicationSchedule value) {
    final parts = value.time.split(':');
    return ScheduleFormData(
      time: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      dose: value.doseValue,
      doseUnit: value.doseUnit,
      repeat: value.repeat,
      // A monthly dose switched to weekly starts on every day, as a new one.
      weekdays: value.weekdays.isEmpty
          ? <int>{1, 2, 3, 4, 5, 6, 7}
          : value.weekdays.toSet(),
      monthDays: value.monthDays.toSet(),
      instructions: value.instructions,
    );
  }

  static String _time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  static String _number(double value) =>
      value.toString().replaceFirst(RegExp(r'\.0$'), '');

  static String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _decimal(String value) =>
      RegExp(r'^(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$').hasMatch(value);
}
