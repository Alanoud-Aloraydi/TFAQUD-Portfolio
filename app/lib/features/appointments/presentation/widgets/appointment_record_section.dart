import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment_group.dart';
import 'package:app/features/appointments/presentation/appointment_record_filter.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_list_body.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_record_empty.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_record_filter_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
