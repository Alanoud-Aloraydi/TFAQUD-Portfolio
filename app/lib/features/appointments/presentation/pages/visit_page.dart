import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/visit_fill_once.dart';
import 'package:app/features/appointments/presentation/widgets/visit_page_body.dart';
import 'package:app/features/appointments/presentation/widgets/visit_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the visit page UI.
class VisitPage extends StatelessWidget {
  const VisitPage({
    super.key,
    required this.appointmentId,
    required this.canManage,
  });

  final String appointmentId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppointmentsCubit>().state;
    CareAppointment? appointment;
    for (final item in state.appointments) {
      if (item.id == appointmentId) appointment = item;
    }
    final visit = context.watch<VisitCubit>().state;
    final Widget page = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        titleSpacing: AppSpacing.lg,
        title: const VisitTitleBar(),
      ),
      body: visitPageBody(
        context,
        state: state,
        visit: visit,
        appointment: appointment,
        canManage: canManage,
      ),
    );
    // Reached from «حضرت», it opens its form once the visit is read.
    return canManage ? VisitFillOnce(child: page) : page;
  }
}
