import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The plan tab's appointments: the upcoming ones, soonest first.
class AppointmentPlanSection extends StatelessWidget {
  const AppointmentPlanSection({
    super.key,
    required this.circleId,
    required this.canManage,
    required this.header,
  });

  final String circleId;
  final bool canManage;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final AppointmentsState state = context.watch<AppointmentsCubit>().state;
    final DateTime now = PatientClockScope.of(context).now();
    final List<CareAppointment> values =
        state.appointments
            .where(
              (item) =>
                  item.status == AppointmentStatus.scheduled &&
                  !item.scheduledAt.isBefore(now),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: <Widget>[
        header,
        const SizedBox(height: AppSpacing.lg),
        if (state.status == AppointmentsLoadStatus.loading && values.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (state.status == AppointmentsLoadStatus.failure)
          RetryView(
            messageKey: state.errorKey ?? 'error.unknown',
            onRetry: () => context.read<AppointmentsCubit>().load(circleId),
          )
        else if (values.isEmpty)
          EmptyStateNote(
            context.tr('appointments.no_upcoming'),
            actionLabel: canManage ? context.tr('add.appointment') : null,
            onAction: canManage
                ? () => context.push<bool>(Routes.newAppointment(circleId))
                : null,
          )
        else
          for (final CareAppointment value in values) ...<Widget>[
            AppointmentCard(
              value: value,
              circleId: circleId,
              canManage: canManage,
              showRelativeDate: true,
            ),
            const SizedBox(height: AppItemCard.listGap),
          ],
      ],
    );
  }
}
