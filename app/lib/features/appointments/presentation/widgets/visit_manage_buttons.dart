import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/show_visit_edit_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
