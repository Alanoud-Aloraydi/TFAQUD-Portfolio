import 'package:app/app/services/reminders/reminder_payloads.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_actions.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_snooze.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A missed task in the attention box, «سجّل» and «تخطي» under it (only
/// «تخطي» once the next task of its kind is due at [now]); tinted when a
/// tapped notification is about it.
class MissedMeasurementCard extends StatelessWidget {
  const MissedMeasurementCard({
    super.key,
    required this.task,
    required this.now,
    required this.circleId,
  });

  final MeasurementOccurrence task;
  final DateTime now;
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final Widget card = MeasurementAttentionCard(
      kind: task.kind,
      title: MeasurementTaskTitle(task: task),
      status: StatusBadge(
        text: context.tr('measurements.unrecorded'),
        tone: StatusTone.attention,
      ),
      // Once the next task of its kind is due a reading would answer that
      // one: only «تخطي» stays, and this line says why.
      lines: <Widget>[
        Text(
          context.tr(
            task.supersededAt(now)
                ? 'measurements.superseded'
                : 'measurements.not_recorded',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      actions: <Widget>[
        MeasurementTaskActions(
          task: task,
          circleId: circleId,
          superseded: task.supersededAt(now),
          sayWhy: false,
        ),
      ],
    );
    return switch (circleId) {
      null => card,
      final String circle => FocusMark(
        itemKey: measurementSnoozeKey(circle, task),
        radius: AppRadius.m,
        inset: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: card,
      ),
    };
  }
}
