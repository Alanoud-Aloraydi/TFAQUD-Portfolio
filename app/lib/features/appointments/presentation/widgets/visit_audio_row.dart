import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/visit_manage_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
