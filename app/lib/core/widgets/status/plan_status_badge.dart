import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/core/widgets/status/plan_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The one badge that shows a plan's [PlanStatus] in every list, card and
/// detail page, so each status has the same colour and label everywhere.
class PlanStatusBadge extends StatelessWidget {
  const PlanStatusBadge(this.status, {super.key});

  final PlanStatus status;

  @override
  Widget build(BuildContext context) => CompactStatusBadge(
    text: context.tr(status.labelKey),
    background: background(status),
    foreground: foreground(status),
  );

  /// The badge fill of [status].
  static Color background(PlanStatus status) => switch (status) {
    PlanStatus.active => AppSemanticColors.selectedSurface,
    PlanStatus.scheduled => AppSemanticColors.surfaceAttention,
    PlanStatus.completed => AppSemanticColors.statusSuccess,
    PlanStatus.stopped => AppSemanticColors.borderPlan,
  };

  /// The text colour of [status], readable on its fill.
  static Color foreground(PlanStatus status) => switch (status) {
    PlanStatus.completed => AppSemanticColors.surfaceContent,
    _ => AppSemanticColors.textPrimary,
  };
}
