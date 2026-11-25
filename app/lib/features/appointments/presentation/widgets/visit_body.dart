import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/localization/appointment_texts.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/visit_audio_row.dart';
import 'package:app/features/appointments/presentation/widgets/visit_manage_actions.dart';
import 'package:app/features/appointments/presentation/widgets/visit_paper_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The visit page once everything it needs has arrived: the appointment it
/// belongs to, its written paper, its recording, and what can be changed.
Widget visitBody(
  BuildContext context,
  CareAppointment appointment,
  VisitState state, {
  required bool canManage,
}) {
  final paper = state.paper;
  return ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      visitHeading(context, appointment),
      const SizedBox(height: AppSpacing.lg),
      visitPaperGroup(context, paper),
      if (canManage) ...[
        const SizedBox(height: AppSpacing.md),
        visitFollowUpButton(context),
      ],
      const SizedBox(height: AppSpacing.md),
      if (paper?.hasAudio == true) visitAudioRow(context, state),
      if (state.recording) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(
            'appointments.recording_time',
            args: [visitDuration(state.recordedSeconds)],
          ),
        ),
      ],
      if (state.errorKey != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(state.errorKey!),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      if (canManage) ...visitManageActions(context, state: state, paper: paper),
    ],
  );
}

/// «إضافة موعد متابعة»: starts a new appointment in the same circle.
Widget visitFollowUpButton(BuildContext context) => OutlinedButton.icon(
  onPressed: () => context.push<bool>(
    CareItemRoutes.newAppointment(context.read<VisitCubit>().circleId),
  ),
  icon: const Icon(CupertinoIcons.calendar),
  label: Text(context.tr('appointments.add_follow_up_appointment')),
);

/// The first block of the visit page: what the appointment was, when it
/// was, and where it was with whom.
Widget visitHeading(BuildContext context, CareAppointment appointment) {
  final String day = appointmentDate(context, appointment.scheduledOn);
  final String clock = clockText(appointment.time);
  final String place = appointment.kind == AppointmentKind.remote
      ? context.tr('appointments.${appointment.remoteMethod}')
      : appointment.place ?? '';
  final String companions = appointmentCompanionLine(context, appointment);
  return MergeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appointmentTitle(context, appointment),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          '$day، $clock',
          style: Theme.of(context).textTheme.bodyMedium,
          semanticsLabel: spoken('$day، $clock'),
        ),
        Text(
          '$place، $companions',
          style: Theme.of(context).textTheme.bodySmall,
          semanticsLabel: spoken('$place، $companions'),
        ),
      ],
    ),
  );
}
