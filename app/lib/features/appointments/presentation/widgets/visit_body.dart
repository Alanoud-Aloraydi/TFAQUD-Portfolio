import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_texts.dart';
import 'package:app/features/appointments/presentation/widgets/show_visit_edit_sheet.dart';
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

/// The recording a visit paper carries: play or stop it, and how long it is.
Widget visitAudioRow(BuildContext context, VisitState state) => Material(
  color: AppSemanticColors.surfaceContent,
  borderRadius: BorderRadius.circular(AppRadius.m),
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        IconButton(
          onPressed: state.playing
              ? context.read<VisitCubit>().stopAudio
              : context.read<VisitCubit>().playAudio,
          icon: Icon(
            state.playing
                ? CupertinoIcons.pause_fill
                : CupertinoIcons.play_fill,
          ),
          tooltip: context.tr(
            state.playing
                ? 'appointments.audio_stop'
                : 'appointments.audio_play',
          ),
        ),
        visitAudioBars(),
        const SizedBox(width: AppSpacing.sm),
        Text(visitDuration(state.audioSeconds)),
      ],
    ),
  ),
);

/// The still waveform beside the play button: 28 bars of fixed heights,
/// a picture of a recording rather than a reading of one.
Widget visitAudioBars() => Expanded(
  child: Row(
    children: [
      for (var index = 0; index < 28; index++)
        Expanded(
          child: Container(
            height: 6.0 + (index * 7 % 13),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: AppSemanticColors.borderControlBase,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
    ],
  ),
);

/// What only someone who may change the visit sees: the two buttons, and
/// the ways out of a recording that is running or already saved.
List<Widget> visitManageActions(
  BuildContext context, {
  required VisitState state,
  VisitPaper? paper,
}) => [
  const SizedBox(height: AppSpacing.md),
  visitManageButtons(context, state, paper),
  if (state.recording)
    TextButton(
      onPressed: context.read<VisitCubit>().cancelRecording,
      child: Text(context.tr('common.cancel')),
    ),
  if (paper?.hasAudio == true && !state.recording)
    TextButton(
      onPressed: state.saving ? null : () => removeVisitAudio(context),
      child: Text(context.tr('appointments.audio_remove')),
    ),
];

/// Asks before throwing the recording away, because it cannot come back.
Future<void> removeVisitAudio(BuildContext context) async {
  final remove = await showAppAlert<bool>(
    context,
    title: context.tr('appointments.audio_remove_confirm'),
    actions: [
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('appointments.audio_remove'),
        value: true,
        destructive: true,
      ),
    ],
  );
  if (remove == true && context.mounted) {
    context.read<VisitCubit>().removeAudio();
  }
}

/// The pair of wide buttons under a visit paper: «تعديل» and the recorder.
Widget visitManageButtons(
  BuildContext context,
  VisitState state,
  VisitPaper? paper,
) => Row(
  children: [
    Expanded(
      child: OutlinedButton.icon(
        onPressed: state.saving || state.recording
            ? null
            : () => showVisitEditSheet(context, paper),
        icon: const Icon(ActionIcons.pencil),
        label: Text(context.tr('appointments.edit_visit')),
      ),
    ),
    const SizedBox(width: AppSpacing.sm),
    Expanded(
      child: OutlinedButton.icon(
        onPressed: state.saving
            ? null
            : state.recording
            ? context.read<VisitCubit>().stopAndSaveRecording
            : context.read<VisitCubit>().startRecording,
        icon: Icon(
          state.recording ? CupertinoIcons.stop_fill : CupertinoIcons.mic,
        ),
        label: Text(
          context.tr(
            state.recording
                ? 'appointments.audio_save'
                : 'appointments.audio_record',
          ),
        ),
      ),
    ),
  ],
);

/// «4:05» for a length in [seconds], and «--:--» when there is none yet.
String visitDuration(int? seconds) {
  if (seconds == null) return '--:--';
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
