import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/visit_audio_bars.dart';
import 'package:app/features/appointments/presentation/widgets/visit_duration.dart';
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
