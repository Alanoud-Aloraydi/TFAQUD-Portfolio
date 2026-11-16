import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_pending_box.dart';
import 'package:flutter/material.dart';

/// What a medicine's plan card holds while it is closed: only a change that
/// waits for a later day. The times and doses are in «تفاصيل الدواء», so the
/// closed card is only what tells the medicines apart.
List<Widget> medicationPlanCardBody({
  required String circleId,
  required MedicationPlan plan,
}) => <Widget>[
  if (plan.pendingVersion case final pending?)
    MedicationPendingBox(
      circleId: circleId,
      current: plan.version,
      pending: pending,
    ),
];
