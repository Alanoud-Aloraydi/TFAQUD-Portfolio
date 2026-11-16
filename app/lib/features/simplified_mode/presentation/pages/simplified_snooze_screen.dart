import 'dart:math' as math;

import 'package:app/core/navigation/routers.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/simplified_snooze_limit.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dark_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snooze_actions.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snooze_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «متى أذكّرك؟»: the detailed mode's ruler, larger, on this mode's dark
/// ground. It scrolls when the text is large, so nothing is cut off.
class SimplifiedSnoozeScreen extends StatefulWidget {
  const SimplifiedSnoozeScreen({super.key, required this.task});

  /// The dose or measurement the patient chose to put off; appointments
  /// are not put off.
  final TodayTask task;

  @override
  State<SimplifiedSnoozeScreen> createState() => _SimplifiedSnoozeScreenState();
}

class _SimplifiedSnoozeScreenState extends State<SimplifiedSnoozeScreen> {
  /// 15 minutes to start with, as the detailed sheet, when there is room.
  int _minutes = 15;

  Future<void> _confirm(int minutes) async {
    await context.read<SimplifiedModeCubit>().snooze(
      task: widget.task,
      after: Duration(minutes: minutes),
    );
    if (mounted) context.go(Routes.simplifiedMode);
  }

  @override
  Widget build(BuildContext context) {
    final SimplifiedModeState state = context
        .watch<SimplifiedModeCubit>()
        .state;
    final int most = simplifiedSnoozeLimit(
      context,
      widget.task,
      state.day,
      state.now,
    ).inMinutes;
    final int minutes = math.min(_minutes, most);
    final DateTime at = state.now.add(Duration(minutes: minutes));
    return SimplifiedDarkPage(
      actions: SimplifiedSnoozeActions(
        onConfirm: state.saving || most <= 0 ? null : () => _confirm(minutes),
      ),
      child: SimplifiedSnoozeBody(
        minutes: minutes,
        maxMinutes: most,
        clock: context.tr(
          'reminders.snooze_at',
          args: <String>[simplifiedClockAt(context, at)],
        ),
        onChanged: (int value) => setState(() => _minutes = value),
      ),
    );
  }
}
