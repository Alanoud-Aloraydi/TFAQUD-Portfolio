import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/visit_audio_row.dart';
import 'package:app/features/appointments/presentation/widgets/visit_duration.dart';
import 'package:app/features/appointments/presentation/widgets/visit_follow_up_button.dart';
import 'package:app/features/appointments/presentation/widgets/visit_heading.dart';
import 'package:app/features/appointments/presentation/widgets/visit_manage_actions.dart';
import 'package:app/features/appointments/presentation/widgets/visit_paper_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
