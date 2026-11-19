import 'package:app/core/constants/plan_limits.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_values.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/models/schedule_form_defaults.dart';
import 'package:flutter/material.dart';

export 'package:app/features/medications/presentation/models/medication_form_dispose.dart';
export 'package:app/features/medications/presentation/models/medication_form_draft.dart';
export 'package:app/features/medications/presentation/models/medication_form_field.dart';
export 'package:app/features/medications/presentation/models/medication_form_schedules.dart';
export 'package:app/features/medications/presentation/models/medication_form_validation.dart';

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
