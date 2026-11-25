import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/localization/appointment_texts.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_today_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// An appointment of «اليوم», by its kind's icon: a [CareItemRow] waiting
/// for «حضرت» (from an hour before); a completed one opens its visit page.
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
      leading: TodayTaskKindIcon(
        icon: appointmentKindIcon(value.kind),
        background: CareVisuals.appointmentTile,
      ),
      title: appointmentTitle(context, value),
      subtitle: appointmentCompanionLine(context, value),
      status: appointmentTodayStatus(context, waiting: waiting),
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
              CareItemRoutes.appointmentVisit(circleId, value.id),
              extra: canManage,
            ),
    );
  }
}

/// What a screen reader says for an appointment's row of «اليوم»: the
/// visit first, its clinic, then the clock and who goes.
String appointmentRowLabel(BuildContext context, CareAppointment value) =>
    <String>[
      appointmentTitle(context, value),
      if (appointmentClinic(value) case final String clinic) clinic,
      clockText(value.time),
      if (appointmentCompanionLine(context, value) case final String who
          when who.isNotEmpty)
        who,
    ].join('، ');

/// The badge of a «اليوم» appointment: waiting once its time has come,
/// else upcoming.
Widget appointmentTodayStatus(BuildContext context, {required bool waiting}) {
  return StatusBadge(
    text: context.tr(
      waiting
          ? 'today_dashboard.status.appointment_waiting'
          : 'today_dashboard.status.upcoming',
    ),
    tone: waiting ? StatusTone.attention : StatusTone.info,
  );
}
