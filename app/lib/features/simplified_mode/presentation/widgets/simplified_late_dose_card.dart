import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_late_dose_answers.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  /// What the card says, in its order, its three answers last.
  static List<String> lines(
    BuildContext context,
    TodayTask task,
    SimplifiedDay day,
    String? snoozed,
  ) => <String>[
    context.tr('simplified_mode.late_question'),
    task.dose!.name,
    simplifiedDoseAmount(context, task.dose!),
    ...simplifiedTaskChips(context, task, day),
    _wasDue(context, task),
    ?snoozed,
    context.tr('simplified_mode.took_now'),
    context.tr('simplified_mode.remind_later'),
    context.tr('simplified_mode.not_taken'),
  ];

  static String _wasDue(BuildContext context, TodayTask task) => context.tr(
    'simplified_mode.was_due',
    args: <String>[simplifiedTime(context, task.time)],
  );

  /// What the card says without its three answers: the buttons name
  /// themselves, and stay their own stops for a screen reader.
  static String _said(
    BuildContext context,
    TodayTask task,
    SimplifiedDay day,
    String? snoozed,
  ) {
    final List<String> said = lines(context, task, day, snoozed);
    return said.sublist(0, said.length - 3).join('، ');
  }

  @override
  Widget build(BuildContext context) => _body(context);

  Widget _body(BuildContext context) {
    final bool saving = context.select<SimplifiedModeCubit, bool>(
      (cubit) => cubit.state.saving,
    );
    final List<String> chips = simplifiedTaskChips(context, task, day);
    return SimplifiedCard(
      color: SimplifiedStyle.attention,
      side: const BorderSide(color: SimplifiedStyle.attentionBorder),
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: 24,
      ),
      child: Column(
        children: <Widget>[
          Semantics(
            label: spoken(_said(context, task, day, snoozed)),
            excludeSemantics: true,
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
                if (simplifiedDoseReason(task, day) == null)
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
                  SimplifiedSnoozedLine(
                    text: text,
                    task: task,
                    day: day,
                    style: SimplifiedStyle.text(
                      SimplifiedStyle.body,
                      color: SimplifiedStyle.ink,
                      weight: AppTextTheme.medium,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SimplifiedLateDoseAnswers(task: task, saving: saving),
        ],
      ),
    );
  }
}
