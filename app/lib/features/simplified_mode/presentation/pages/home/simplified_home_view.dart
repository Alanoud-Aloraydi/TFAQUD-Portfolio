import 'package:app/core/widgets/layout/logo_refresh.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_home_body.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_load_failed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// The home for [state]: the day, a note that it failed, or that it loads.
class SimplifiedHomeView extends StatelessWidget {
  const SimplifiedHomeView({super.key, required this.state});

  final SimplifiedModeState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SimplifiedColors.canvas,
      body: SafeArea(
        child: switch ((state.status, state.day, state.schedule)) {
          (_, final SimplifiedDay day, final TodaySchedule schedule) =>
            LogoRefresh(
              onRefresh: context.read<SimplifiedModeCubit>().load,
              child: SimplifiedHomeBody(
                day: day,
                schedule: schedule,
                now: state.now,
                snoozes: state.snoozes,
              ),
            ),
          (SimplifiedModeStatus.failure, _, _) => SimplifiedLoadFailed(
            messageKey: state.messageKey,
          ),
          _ => const LoadingNote(),
        },
      ),
    );
  }
}
