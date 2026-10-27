import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:flutter/material.dart';

class MedicationFormData {
  MedicationFormData(MedicationPlan? plan)
    : name = TextEditingController(text: plan?.version.name),
      strength = TextEditingController(text: plan?.version.strength),
      reason = TextEditingController(text: plan?.version.reason),
      instructions = TextEditingController(text: plan?.version.instructions),
      form = plan?.version.dosageForm ?? DosageForm.tablet,
      startsOn = plan?.version.startsOn ?? DateUtils.dateOnly(DateTime.now()),
      endsOn = plan?.version.endsOn,
      schedules = plan == null
          ? [_newSchedule()]
          : plan.version.schedules.map(_fromSchedule).toList();

  final TextEditingController name;
  final TextEditingController strength;
  final TextEditingController reason;
  final TextEditingController instructions;
  DosageForm form;
  DateTime startsOn;
  DateTime? endsOn;
  final List<ScheduleFormData> schedules;

  void addSchedule() => schedules.add(_newSchedule());

  void removeSchedule(int index) => schedules.removeAt(index).dispose();

  MedicationPlanDraft? toDraft() {
    if (name.text.trim().isEmpty ||
        (endsOn != null && endsOn!.isBefore(startsOn))) {
      return null;
    }
    final scheduleDrafts = <MedicationScheduleDraft>[];
    for (final item in schedules) {
      final dose = double.tryParse(item.doseController.text.trim());
      if (dose == null || dose <= 0 || item.weekdays.isEmpty) return null;
      scheduleDrafts.add(
        MedicationScheduleDraft(
          time: _time(item.time),
          doseValue: dose,
          doseUnit: form.doseUnit,
          weekdays: item.weekdays.toList()..sort(),
          instructions: _optional(item.instructionsController.text),
        ),
      );
    }
    return MedicationPlanDraft(
      name: name.text.trim(),
      strength: _optional(strength.text),
      dosageForm: form,
      reason: _optional(reason.text),
      instructions: _optional(instructions.text),
      startsOn: startsOn,
      endsOn: endsOn,
      schedules: scheduleDrafts,
    );
  }

  void dispose() {
    name.dispose();
    strength.dispose();
    reason.dispose();
    instructions.dispose();
    for (final schedule in schedules) {
      schedule.dispose();
    }
  }

  static ScheduleFormData _newSchedule() => ScheduleFormData(
    time: const TimeOfDay(hour: 8, minute: 0),
    dose: 1,
    weekdays: {1, 2, 3, 4, 5, 6, 7},
  );

  static ScheduleFormData _fromSchedule(MedicationSchedule value) {
    final parts = value.time.split(':');
    return ScheduleFormData(
      time: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      dose: value.doseValue,
      weekdays: value.weekdays.toSet(),
      instructions: value.instructions,
    );
  }

  static String _time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  static String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
