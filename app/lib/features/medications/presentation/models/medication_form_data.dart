import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:flutter/material.dart';

enum MedicationFormField { name, strength, period, dose, weekdays }

class MedicationFormIssue {
  const MedicationFormIssue(this.field, {this.scheduleIndex});

  final MedicationFormField field;
  final int? scheduleIndex;
}

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
      startsOn = plan?.version.startsOn ?? DateUtils.dateOnly(DateTime.now()),
      endsOn = plan?.version.endsOn,
      effectiveFromOn = plan == null
          ? null
          : DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1))),
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
  DateTime startsOn;
  DateTime? endsOn;
  DateTime? effectiveFromOn;
  final List<ScheduleFormData> schedules;

  void addSchedule() => schedules.add(_newSchedule());

  void removeSchedule(int index) => schedules.removeAt(index).dispose();

  MedicationFormIssue? firstIssue() {
    if (name.text.trim().isEmpty) {
      return const MedicationFormIssue(MedicationFormField.name);
    }
    final strengthText = strength.text.trim();
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
      final doseText = schedule.doseController.text.trim();
      final dose = _decimal(doseText) ? double.tryParse(doseText) : null;
      if (dose == null || dose <= 0) {
        return MedicationFormIssue(
          MedicationFormField.dose,
          scheduleIndex: index,
        );
      }
      if (schedule.weekdays.isEmpty) {
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
    final strengthText = strength.text.trim();
    final strengthValue = double.parse(strengthText);
    final scheduleDrafts = <MedicationScheduleDraft>[];
    for (final item in schedules) {
      final doseText = item.doseController.text.trim();
      final dose = double.parse(doseText);
      scheduleDrafts.add(
        MedicationScheduleDraft(
          time: _time(item.time),
          doseValue: dose,
          doseUnit: item.doseUnit,
          weekdays: item.weekdays.toList()..sort(),
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

  static ScheduleFormData _newSchedule() => ScheduleFormData(
    time: const TimeOfDay(hour: 8, minute: 0),
    dose: 0.5,
    doseUnit: DoseUnit.tablet,
    weekdays: {1, 2, 3, 4, 5, 6, 7},
  );

  static ScheduleFormData _fromSchedule(MedicationSchedule value) {
    final parts = value.time.split(':');
    return ScheduleFormData(
      time: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      dose: value.doseValue,
      doseUnit: value.doseUnit,
      weekdays: value.weekdays.toSet(),
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
