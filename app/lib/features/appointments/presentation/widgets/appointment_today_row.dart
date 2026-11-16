import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_today_actions.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_row_label.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// An appointment of «اليوم»: a [CareItemRow] that waits for confirmation
/// once its time has passed, with «حضرت» and its two choices from an hour
/// before. A completed one opens its visit page.
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
    final DateTime now = PatientClockScope.of(context).now();
    final bool waiting = !value.scheduledAt.isAfter(now);
    final String? circleId = this.circleId;
    return CareItemRow(
      time: clockText(value.time),
      spokenLabel: appointmentRowLabel(context, value),
      tone: waiting ? TodayRowTone.attention : TodayRowTone.normal,
      leading: const TodayTaskKindIcon(
        icon: CareVisuals.appointmentIcon,
        background: CareVisuals.appointmentTile,
      ),
      title: appointmentTitle(context, value),
      subtitle: appointmentCompanionLine(context, value),
      status: StatusBadge(
        text: context.tr(
          waiting
              ? 'today_dashboard.status.appointment_waiting'
              : 'today_dashboard.status.upcoming',
        ),
        tone: waiting ? StatusTone.attention : StatusTone.info,
      ),
      actions: appointmentTodayActions(
        context,
        value: value,
        now: now,
        circleId: circleId,
        canManage: canManage,
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
