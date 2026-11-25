import 'dart:async';

import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_loading.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/show_visit_edit_sheet.dart';
import 'package:app/features/appointments/presentation/widgets/visit_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
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

/// What sits under the visit page's bar: a spinner while either half of
/// the page loads, a way to try again when one failed, else the visit.
Widget visitPageBody(
  BuildContext context, {
  required AppointmentsState state,
  required VisitState visit,
  required CareAppointment? appointment,
  required bool canManage,
}) {
  if (state.status == AppointmentsLoadStatus.loading || visit.loading) {
    return const LoadingNote();
  }
  if (visit.loadFailed) {
    return Center(
      child: TextButton(
        onPressed: context.read<VisitCubit>().load,
        child: Text(context.tr(visit.errorKey ?? 'error.unknown')),
      ),
    );
  }
  if (appointment == null) {
    return Center(
      child: TextButton(
        onPressed: () => context.read<AppointmentsCubit>().load(
          context.read<VisitCubit>().circleId,
        ),
        child: Text(context.tr(state.errorKey ?? 'error.not_found')),
      ),
    );
  }
  return visitBody(context, appointment, visit, canManage: canManage);
}

/// The glass bar at the top of the visit page: «رجوع» and the title.
class VisitTitleBar extends StatelessWidget {
  const VisitTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadius.capsule),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            TextButton.icon(
              onPressed: context.pop,
              icon: const Icon(CupertinoIcons.arrow_right),
              label: Text(context.tr('common.back')),
            ),
            Expanded(
              child: Text(
                context.tr('appointments.visit_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 88),
          ],
        ),
      ),
    );
  }
}
