import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/presentation/models/plan_reading_draft.dart';
import 'package:app/features/measurements/presentation/models/plan_schedule_draft.dart';
import 'package:app/features/measurements/presentation/widgets/plan_add_reading_row.dart';
import 'package:app/features/measurements/presentation/widgets/plan_reading_state_block.dart';
import 'package:app/features/measurements/presentation/widgets/plan_reading_time_row.dart';
import 'package:flutter/material.dart';

/// The rows of every reading of a plan: its time, then its «حالة القياس»,
/// and «إضافة قراءة» ([onAdd]) while more may be added. [onEdit] runs a
/// change and clears the error shown; [errorKey] «times_repeat» is said
/// under each of the same times.
List<Widget> planReadingRows({
  required List<PlanReadingDraft> readings,
  required MeasurementKind kind,
  required String? errorKey,
  required void Function(VoidCallback change) onEdit,
  required VoidCallback onAdd,
}) => <Widget>[
  for (int index = 0; index < readings.length; index++) ...[
    PlanReadingTimeRow(
      readings: readings,
      index: index,
      repeated: errorKey == 'measurements.times_repeat',
      onEdit: onEdit,
    ),
    PlanReadingStateBlock(
      readings: readings,
      index: index,
      kind: kind,
      onEdit: onEdit,
    ),
  ],
  if (readings.length < PlanScheduleDraft.maxReadings)
    PlanAddReadingRow(onAdd: onAdd),
];
