import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/task_visuals.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// A dose whose time passed unrecorded: ask, and offer to record it now.
class SimplifiedLateDoseCard extends StatelessWidget {
  const SimplifiedLateDoseCard({
    super.key,
    required this.task,
    required this.day,
    required this.snoozed,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «سأذكّرك 2:09 مساءً» when the dose is put off.
  final String? snoozed;

  /// What the card says, in its order, its two answers last.
  static List<String> lines(
    BuildContext context,
    TodayTask task,
    SimplifiedDay day,
    String? snoozed,
  ) => <String>[
    context.tr('simplified_mode.late_question'),
    task.dose!.name,
    simplifiedDoseAmount(context, task.dose!),
    simplifiedStrength(context, task.dose!),
    ...simplifiedTaskChips(context, task, day),
    _wasDue(context, task),
    ?snoozed,
    context.tr('simplified_mode.took_now'),
    context.tr('simplified_mode.remind_later'),
  ];

  static String _wasDue(BuildContext context, TodayTask task) => context.tr(
    'simplified_mode.was_due',
    args: <String>[simplifiedTime(context, task.time)],
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: lines(context, task, day, snoozed).join('، '),
      excludeSemantics: true,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final bool saving = context.select<SimplifiedModeCubit, bool>(
      (cubit) => cubit.state.saving,
    );
    final List<String> chips = simplifiedTaskChips(context, task, day);
    return SimplifiedCard(
      color: SimplifiedStyle.attention,
      side: const BorderSide(color: SimplifiedStyle.attentionEdge, width: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: 24,
      ),
      child: Column(
        children: <Widget>[
          Text(
            context.tr('simplified_mode.late_question'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(SimplifiedStyle.headline),
          ),
          const SizedBox(height: 12),
          MedicinePhoto(
            circleId: day.circleId,
            planId: task.dose!.planId,
            height: 124,
            width: 124,
            radius: 30,
            iconSize: 48,
          ),
          const SizedBox(height: 12),
          Text(
            task.dose!.name,
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(SimplifiedStyle.name),
          ),
          Text(
            simplifiedDoseAmount(context, task.dose!),
            style: SimplifiedStyle.head(SimplifiedStyle.headline),
          ),
          Text(
            simplifiedStrength(context, task.dose!),
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              weight: AppTextTheme.medium,
            ),
          ),
          if (chips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                for (final String chip in chips) SimplifiedChip(chip),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _wasDue(context, task),
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              color: SimplifiedStyle.attentionInk,
              weight: AppTextTheme.bold,
            ),
          ),
          if (snoozed case final String text)
            Text(
              text,
              style: SimplifiedStyle.text(
                SimplifiedStyle.body,
                color: SimplifiedStyle.ink,
                weight: AppTextTheme.medium,
              ),
            ),
          const SizedBox(height: 16),
          SimplifiedButton(
            label: context.tr('simplified_mode.took_now'),
            icon: AppIcons.check,
            onPressed: saving ? null : () => _take(context),
          ),
          const SizedBox(height: 12),
          SimplifiedButton(
            label: context.tr('simplified_mode.remind_later'),
            tone: SimplifiedButtonTone.secondary,
            onPressed: () => context.push(Routes.simplifiedSnooze, extra: task),
          ),
        ],
      ),
    );
  }
}
