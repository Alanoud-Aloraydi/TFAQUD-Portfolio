import 'dart:async';

import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/show_visit_edit_sheet.dart';
import 'package:app/features/appointments/presentation/widgets/visit_page_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

/// Opens «تعديل ورقة الزيارة» by itself, once, as soon as the visit is
/// read, when the page was reached from «حضرت» (its address asks with
/// fill=1): the person lands on the form to fill in. A later reload of the
/// page does not open it again.
class VisitFillOnce extends StatefulWidget {
  const VisitFillOnce({super.key, required this.child});

  final Widget child;

  @override
  State<VisitFillOnce> createState() => _VisitFillOnceState();
}

class _VisitFillOnceState extends State<VisitFillOnce> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) => BlocListener<VisitCubit, VisitState>(
    listenWhen: (VisitState before, VisitState now) =>
        before.loading && !now.loading && !now.loadFailed,
    listener: (BuildContext context, VisitState state) {
      final Uri address = GoRouterState.of(context).uri;
      if (_opened || address.queryParameters['fill'] != '1') return;
      _opened = true;
      unawaited(showVisitEditSheet(context, state.paper));
    },
    child: widget.child,
  );
}
