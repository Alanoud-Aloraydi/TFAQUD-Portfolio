import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/overdue_appointment_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// An appointment of an earlier day nobody closed yet. Managers answer it
/// here with the same confirmation as on the appointment's card.
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: CareItemRow(
        time: clockText(value.time),
        tone: TodayRowTone.attention,
        leading: const TodayTaskKindIcon(
          icon: CareVisuals.appointmentIcon,
          background: CareVisuals.appointmentTile,
        ),
        title: appointmentTitle(context, value),
        subtitle: formatMedicationDate(context, value.scheduledOn),
        status: StatusBadge(
          text: context.tr('today_dashboard.status.appointment_waiting'),
          tone: StatusTone.attention,
        ),
        actions: canManage
            ? OverdueAppointmentActions(value: value, circleId: circleId)
            : null,
      ),
    );
  }
}
