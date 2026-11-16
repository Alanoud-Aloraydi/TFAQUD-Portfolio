import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The three answers under a late dose, in the colours both modes give a
/// task: «أخذته الآن» in the baby violet, «ذكّرني لاحقًا» in the honey,
/// «ما أخذتها» in the grey.
class SimplifiedLateDoseAnswers extends StatelessWidget {
  const SimplifiedLateDoseAnswers({
    super.key,
    required this.task,
    required this.saving,
  });

  final TodayTask task;

  /// A record is on its way to the server, so the two answers that record
  /// are not pressable until it lands.
  final bool saving;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      SimplifiedButton(
        label: context.tr('simplified_mode.took_now'),
        icon: AppIcons.check,
        tone: SimplifiedButtonTone.answer,
        onPressed: saving ? null : () => _take(context),
      ),
      const SizedBox(height: 12),
      SimplifiedButton(
        label: context.tr('simplified_mode.remind_later'),
        tone: SimplifiedButtonTone.later,
        onPressed: () => context.push(Routes.simplifiedSnooze, extra: task),
      ),
      const SizedBox(height: 12),
      // A dose that will not be taken has somewhere to go: without
      // this it stays late for ever, and the family never learns why.
      SimplifiedButton(
        label: context.tr('simplified_mode.not_taken'),
        tone: SimplifiedButtonTone.skip,
        onPressed: saving
            ? null
            : () => context.push(Routes.simplifiedSkip, extra: task),
      ),
    ],
  );

  Future<void> _take(BuildContext context) async {
    final SimplifiedModeCubit cubit = context.read<SimplifiedModeCubit>();
    final DateTime? takenAt = await cubit.takeDose(task.dose!);
    if (takenAt == null || !context.mounted) return;
    unawaited(
      context.push(
        Routes.simplifiedDone,
        extra: SimplifiedDoneMessage.doseTaken(task.dose!.name, takenAt),
      ),
    );
  }
}
