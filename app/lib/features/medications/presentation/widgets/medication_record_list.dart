import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The medicines «السجل» keeps under its filter, or the note that this
/// filter has none.
List<Widget> medicationRecordList(
  BuildContext context, {
  required String circleId,
  required List<MedicationPlan> plans,
}) {
  if (plans.isEmpty) {
    return <Widget>[
      EmptyStateNote.section(context.tr('medications.no_records')),
    ];
  }
  return <Widget>[
    for (final plan in plans) ...<Widget>[
      MedicationRecordCard(circleId: circleId, plan: plan),
      const SizedBox(height: AppItemCard.listGap),
    ],
  ];
}
