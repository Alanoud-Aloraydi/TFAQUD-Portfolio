import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/scroll_insets.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment_group.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_loading.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_attend_button.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_companion_chips.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_lead_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «السجل»'s appointments, newest first, one card a booking, read-only.
class AppointmentRecordSection extends StatefulWidget {
  const AppointmentRecordSection({
    super.key,
    required this.circleId,
    required this.header,
    required this.canManage,
  });

  final String circleId;
  final Widget header;

  /// Whether «ورقة الزيارة» opens for writing from here.
  final bool canManage;

  @override
  State<AppointmentRecordSection> createState() =>
      _AppointmentRecordSectionState();
}

class _AppointmentRecordSectionState extends State<AppointmentRecordSection> {
  AppointmentRecordFilter _filter = AppointmentRecordFilter.all;

  @override
  Widget build(BuildContext context) {
    final AppointmentsState state = context.watch<AppointmentsCubit>().state;
    final DateTime now = PatientClockScope.of(context).now();
    final List<AppointmentGroup> values = AppointmentGroup.of(
      _filter.pick(state.appointments, now),
      state.appointments,
      now,
    );
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: <Widget>[
        widget.header,
        const SizedBox(height: AppSpacing.md),
        AppointmentRecordFilterMenu(
          selected: _filter,
          onChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: AppSpacing.md),
        ...appointmentListBody(
          context,
          state: state,
          values: values,
          circleId: widget.circleId,
          empty: AppointmentRecordEmpty(
            circleId: widget.circleId,
            // Only a circle with no visit at all, as «الخطة» does.
            canAdd: widget.canManage && state.appointments.isEmpty,
          ),
          canManage: widget.canManage,
          editable: false,
        ),
      ],
    );
  }
}

/// «السجل»'s visits when there are none, with «إضافة موعد طبي» when
/// [canAdd], as «الخطة» offers it.
class AppointmentRecordEmpty extends StatelessWidget {
  const AppointmentRecordEmpty({
    super.key,
    required this.circleId,
    required this.canAdd,
  });

  final String circleId;
  final bool canAdd;

  @override
  Widget build(BuildContext context) => EmptyStateNote.section(
    context.tr('appointments.no_records'),
    actionLabel: canAdd ? context.tr('add.appointment') : null,
    onAction: canAdd
        ? () => context.push<bool>(CareItemRoutes.newAppointment(circleId))
        : null,
  );
}

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
