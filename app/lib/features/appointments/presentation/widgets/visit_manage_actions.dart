import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/appointments/domain/entities/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/show_visit_edit_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
