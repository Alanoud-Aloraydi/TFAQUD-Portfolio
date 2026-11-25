import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_texts.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_today_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A visit nobody closed yet that waits in «يحتاج انتباهك»: one of an
/// earlier day, or today's once another task came after it. It asks what
/// it asks on its row ([appointmentTodayActions]), until it is missed.
class OverdueAppointmentCard extends StatelessWidget {
  const OverdueAppointmentCard({
    super.key,
    required this.value,
    required this.circleId,
    required this.canManage,
  });

  final CareAppointment value;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final Widget? actions = appointmentTodayActions(
      context,
      value: value,
      now: PatientClockScope.of(context).now(),
      circleId: circleId,
      canManage: canManage,
    );
    if (actions == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: CareItemRow(
        time: clockText(value.time),
        tone: TodayRowTone.attention,
        leading: TodayTaskKindIcon(
          icon: appointmentKindIcon(value.kind),
          background: CareVisuals.appointmentTile,
        ),
        title: appointmentTitle(context, value),
        subtitle: formatMedicationDate(context, value.scheduledOn),
        status: StatusBadge(
          text: context.tr('today_dashboard.status.appointment_waiting'),
          tone: StatusTone.attention,
        ),
        actions: actions,
      ),
    );
  }
}
