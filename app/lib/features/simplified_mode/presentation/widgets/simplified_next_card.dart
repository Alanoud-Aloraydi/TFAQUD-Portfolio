import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_open_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/task_visuals.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The next task: the medicine's photo first (how the patient knows it),
/// then the time, the name and what to take.
class SimplifiedNextCard extends StatelessWidget {
  const SimplifiedNextCard({
    super.key,
    required this.task,
    required this.day,
    required this.schedule,
    required this.now,
    required this.snoozed,
  });

  final TodayTask task;
  final SimplifiedDay day;
  final TodaySchedule schedule;
  final DateTime now;

  /// «سأذكّرك 2:09 مساءً» when the task is put off.
  final String? snoozed;

  /// What the card says, in its order.
  static List<String> lines(
    BuildContext context,
    TodayTask task,
    SimplifiedDay day,
    DateTime now,
    String? snoozed,
  ) {
    final PrayerPeriod? period = _period(task, day);
    return <String>[
      snoozed ?? _when(context, task, now),
      simplifiedTime(context, task.time),
      if (period != null) simplifiedPeriod(context, period),
      simplifiedTaskTitle(context, task),
      if (task.dose case final dose?) ...<String>[
        simplifiedDoseAmount(context, dose),
        simplifiedStrength(context, dose),
      ],
      ...simplifiedTaskChips(context, task, day),
    ];
  }

  static PrayerPeriod? _period(TodayTask task, SimplifiedDay day) =>
      day.prayers == null ? null : prayerPeriodOf(task.time, day.prayers!);

  /// «التالي · بعد ساعتين», or «فات موعده».
  static String _when(BuildContext context, TodayTask task, DateTime now) =>
      task.status == TodayTaskStatus.late
      ? context.tr('simplified_mode.status.late')
      : context.tr(
          'simplified_mode.next_in',
          args: <String>[simplifiedUntil(context, task.scheduledAt, now)],
        );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: lines(context, task, day, now, snoozed).join('، '),
      excludeSemantics: true,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final bool recordable =
        task.kind != TodayTaskKind.appointment && schedule.canRecord(task);
    final PrayerPeriod? period = _period(task, day);
    final String when = snoozed ?? _when(context, task, now);
    return SimplifiedCard(
      padding: EdgeInsets.zero,
      side: const BorderSide(color: SimplifiedStyle.ink, width: 2),
      onTap: recordable
          ? () => openSimplifiedTask(context, task, day.circleId)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              _hero(),
              if (period != null)
                PositionedDirectional(
                  top: 14,
                  start: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: SimplifiedStyle.surface,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      simplifiedPeriod(context, period),
                      style: SimplifiedStyle.head(SimplifiedStyle.caption),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(SimplifiedStyle.pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  when,
                  style: SimplifiedStyle.label(
                    SimplifiedStyle.caption,
                    color: task.status == TodayTaskStatus.late
                        ? SimplifiedStyle.attentionInk
                        : SimplifiedStyle.muted,
                  ),
                ),
                Text(
                  simplifiedTime(context, task.time),
                  style: SimplifiedStyle.head(
                    SimplifiedStyle.time,
                    height: 1.1,
                  ),
                ),
                const Divider(height: 28, color: SimplifiedStyle.line),
                Text(
                  simplifiedTaskTitle(context, task),
                  style: SimplifiedStyle.head(SimplifiedStyle.name),
                ),
                ..._details(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    if (task.kind == TodayTaskKind.medication) {
      return MedicinePhoto(
        circleId: day.circleId,
        planId: task.dose!.planId,
        height: 210,
        radius: 0,
        iconSize: 96,
      );
    }
    final bool measurement = task.kind == TodayTaskKind.measurement;
    return Container(
      height: 150,
      width: double.infinity,
      color: measurement
          ? CareVisuals.measurementTile
          : CareVisuals.appointmentTile,
      child: Icon(
        measurement
            ? measurementIcon(task.measurement!.kind)
            : CareVisuals.appointmentIcon,
        size: 80,
        color: AppSemanticColors.onSettingsTile,
      ),
    );
  }

  List<Widget> _details(BuildContext context) {
    final List<String> chips = simplifiedTaskChips(context, task, day);
    return <Widget>[
      if (task.dose case final dose?) ...<Widget>[
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 10,
          children: <Widget>[
            Text(
              simplifiedDoseAmount(context, dose),
              style: SimplifiedStyle.head(SimplifiedStyle.headline),
            ),
            Text(
              simplifiedStrength(context, dose),
              style: SimplifiedStyle.text(
                SimplifiedStyle.body,
                weight: AppTextTheme.medium,
              ),
            ),
          ],
        ),
      ],
      if (chips.isNotEmpty) ...<Widget>[
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String chip in chips) SimplifiedChip(chip),
          ],
        ),
      ],
    ];
  }
}
