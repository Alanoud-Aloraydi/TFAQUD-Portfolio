import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Where a dose stands against its time: upcoming, due, late, or not
/// recorded. A missed dose of today or yesterday still says «غير مسجلة»,
/// because it is not proof the dose was skipped.
class DoseTimingBadge extends StatelessWidget {
  const DoseTimingBadge({
    super.key,
    required this.state,
    required this.scheduledOn,
  });

  final DoseTimingState? state;
  final DateTime scheduledOn;

  @override
  Widget build(BuildContext context) {
    final DoseTimingState? state = this.state;
    if (state == null) return const SizedBox.shrink();
    final DateTime yesterday = DateUtils.dateOnly(
      PatientClockScope.of(context).today(),
    ).subtract(const Duration(days: 1));
    final bool recentMissed =
        state == DoseTimingState.missed &&
        !DateUtils.dateOnly(scheduledOn).isBefore(yesterday);
    return StatusBadge(
      text: context.tr(
        recentMissed
            ? 'medications.timing.unrecorded'
            : 'medications.timing.${state.name}',
      ),
      tone: switch (state) {
        DoseTimingState.upcoming => StatusTone.info,
        DoseTimingState.due || DoseTimingState.late => StatusTone.attention,
        DoseTimingState.missed =>
          recentMissed ? StatusTone.attention : StatusTone.danger,
      },
    );
  }
}
