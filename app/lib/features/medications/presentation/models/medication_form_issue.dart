import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:flutter/material.dart';

/// Describes one medication form validation issue.
class MedicationFormIssue {
  const MedicationFormIssue(this.field, {this.scheduleIndex});

  final MedicationFormField field;
  final int? scheduleIndex;
}
