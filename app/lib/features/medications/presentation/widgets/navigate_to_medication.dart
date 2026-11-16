import 'package:app/core/navigation/routers.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Opens the medicine of [occurrence]. [canManage] travels with it, because
/// the page shows the edit button only to a member who may change the plan.
void openMedication(
  BuildContext context,
  String circleId,
  DoseOccurrence occurrence,
  bool canManage,
) {
  context.push(
    Routes.medicationDetails(circleId, occurrence.planId),
    extra: canManage,
  );
}
