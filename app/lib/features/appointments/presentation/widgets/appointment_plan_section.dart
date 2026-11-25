import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/scroll_insets.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment_group.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_loading.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_attend_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The plan tab's appointments: the upcoming ones, soonest first, one card
/// for each booking.
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
    final List<AppointmentGroup> values = AppointmentGroup.of(
      upcomingAppointments(state.appointments, now),
      state.appointments,
      now,
    );
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: <Widget>[
        header,
        const SizedBox(height: AppSpacing.lg),
        ...appointmentListBody(
          context,
          state: state,
          values: values,
          circleId: circleId,
          empty: EmptyStateNote.section(
            context.tr('appointments.no_upcoming'),
            actionLabel: canManage ? context.tr('add.appointment') : null,
            onAction: canManage
                ? () => context.push<bool>(
                    CareItemRoutes.newAppointment(circleId),
                  )
                : null,
          ),
          canManage: canManage,
          showRelativeDate: true,
        ),
      ],
    );
  }
}
