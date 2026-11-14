import 'package:app/core/widgets/status/plan_status.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The badge of a plan's [PlanStatus] in every list, card and detail page:
/// the shared [StatusBadge], in the tone of the status.
class PlanStatusBadge extends StatelessWidget {
  const PlanStatusBadge(this.status, {super.key});

  final PlanStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusBadge(text: context.tr(status.labelKey), tone: tone(status));

  /// The tone of [status]: each one has its own.
  static StatusTone tone(PlanStatus status) => switch (status) {
    PlanStatus.active => StatusTone.success,
    PlanStatus.scheduled => StatusTone.info,
    PlanStatus.completed => StatusTone.neutral,
    PlanStatus.stopped => StatusTone.muted,
  };
}
