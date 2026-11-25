import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_loading.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/visit_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
