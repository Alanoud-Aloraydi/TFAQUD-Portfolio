import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// An appointment of «اليوم»: a [CareItemRow] that waits for confirmation
/// once its time has passed. A completed one opens its visit page; otherwise
/// the row is not tappable.
class AppointmentTodayRow extends StatelessWidget {
  const AppointmentTodayRow({
    super.key,
    required this.value,
    this.circleId,
    this.canManage = false,
  });

  final CareAppointment value;

  /// Needed to open the visit page; null leaves the row plain.
  final String? circleId;

  /// Passed on to the visit page.
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final bool waiting = !value.scheduledAt.isAfter(
      PatientClockScope.of(context).now(),
    );
    final String? circleId = this.circleId;
    return CareItemRow(
      time: clockText(value.time),
      tone: waiting ? TodayRowTone.attention : TodayRowTone.normal,
      leading: const TodayTaskKindIcon(
        icon: CareVisuals.appointmentIcon,
        background: CareVisuals.appointmentTile,
      ),
      title: appointmentTitle(context, value),
      subtitle: appointmentCompanionLine(context, value),
      status: TodayTaskStatusBadge(
        text: context.tr(
          waiting
              ? 'today_dashboard.status.appointment_waiting'
              : 'today_dashboard.status.upcoming',
        ),
        tone: waiting ? TodayStatusTone.attention : TodayStatusTone.neutral,
      ),
      onTap: circleId == null || value.status != AppointmentStatus.completed
          ? null
          : () => context.push(
              Routes.appointmentVisit(circleId, value.id),
              extra: canManage,
            ),
    );
  }
}
