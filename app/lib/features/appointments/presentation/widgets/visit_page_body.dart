import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/visit_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
