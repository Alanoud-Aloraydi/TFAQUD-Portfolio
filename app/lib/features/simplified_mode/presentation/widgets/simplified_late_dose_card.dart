import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_late_dose_answers.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

  @override
  Widget build(BuildContext context) => _body(context);

  Widget _body(BuildContext context) {
    final bool saving = context.select<SimplifiedModeCubit, bool>(
      (cubit) => cubit.state.saving,
    );
    return SimplifiedCard(
      color: SimplifiedColors.attention,
      side: const BorderSide(color: SimplifiedColors.attentionBorder),
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: 24,
      ),
      child: Column(
        children: <Widget>[
          Semantics(
            label: spoken(simplifiedLateDoseSaid(context, task, day, snoozed)),
            excludeSemantics: true,
            child: SimplifiedLateDoseText(
              task: task,
              day: day,
              snoozed: snoozed,
            ),
          ),
          const SizedBox(height: 16),
          SimplifiedLateDoseAnswers(task: task, saving: saving),
        ],
      ),
    );
  }
}

/// What the late dose card says above its three answers: the question,
/// the medicine, what to take, and how late it is.
class SimplifiedLateDoseText extends StatelessWidget {
  const SimplifiedLateDoseText({
    super.key,
    required this.task,
    required this.day,
    required this.snoozed,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «سأذكّرك 2:09 مساءً» when the dose is put off.
  final String? snoozed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          context.tr('simplified_mode.late_question'),
          textAlign: TextAlign.center,
          style: SimplifiedStyle.head(SimplifiedStyle.headline),
        ),
        const SizedBox(height: 12),
        SimplifiedLateDoseMedicine(task: task, day: day),
        SimplifiedLateDoseDue(task: task, day: day, snoozed: snoozed),
      ],
    );
  }
}

/// How the late dose is taken and how late it is: its chips, when it was
/// due, and what it was put off to.
class SimplifiedLateDoseDue extends StatelessWidget {
  const SimplifiedLateDoseDue({
    super.key,
    required this.task,
    required this.day,
    required this.snoozed,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «سأذكّرك 2:09 مساءً» when the dose is put off.
  final String? snoozed;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = simplifiedTaskChips(context, task, day);
    return Column(
      children: <Widget>[
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
          simplifiedLateDoseWasDue(context, task),
          style: SimplifiedStyle.text(
            SimplifiedStyle.body,
            color: SimplifiedColors.attentionInk,
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
              color: SimplifiedColors.ink,
              weight: AppTextTheme.medium,
            ),
          ),
      ],
    );
  }
}

/// The medicine of the late dose card: its photo, its name and what to
/// take.
class SimplifiedLateDoseMedicine extends StatelessWidget {
  const SimplifiedLateDoseMedicine({
    super.key,
    required this.task,
    required this.day,
  });

  final TodayTask task;
  final SimplifiedDay day;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
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
      ],
    );
  }
}

/// What the late dose card says, in its order, its three answers last.
List<String> simplifiedLateDoseLines(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
  String? snoozed,
) => <String>[
  context.tr('simplified_mode.late_question'),
  task.dose!.name,
  simplifiedDoseAmount(context, task.dose!),
  ...simplifiedTaskChips(context, task, day),
  simplifiedLateDoseWasDue(context, task),
  ?snoozed,
  context.tr('simplified_mode.took_now'),
  context.tr('simplified_mode.remind_later'),
  context.tr('simplified_mode.not_taken'),
];

/// «كان موعده 6:00 مساءً».
String simplifiedLateDoseWasDue(BuildContext context, TodayTask task) =>
    context.tr(
      'simplified_mode.was_due',
      args: <String>[simplifiedTime(context, task.time)],
    );

/// What the card says without its three answers: the buttons name
/// themselves, and stay their own stops for a screen reader.
String simplifiedLateDoseSaid(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
  String? snoozed,
) {
  final List<String> said = simplifiedLateDoseLines(
    context,
    task,
    day,
    snoozed,
  );
  return said.sublist(0, said.length - 3).join('، ');
}
