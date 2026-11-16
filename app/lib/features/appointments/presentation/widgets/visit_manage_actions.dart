import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/visit_edit_actions.dart';
import 'package:app/features/appointments/presentation/widgets/visit_manage_buttons.dart';
import 'package:easy_localization/easy_localization.dart';
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
