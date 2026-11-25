import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_actions.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_snooze.dart';
import 'package:app/features/measurements/presentation/widgets/reading_number_field.dart';
import 'package:app/features/measurements/presentation/widgets/reading_titles.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The measurements that need attention. On «اليوم» they sit inside the one
/// «يحتاج انتباهك» box with the doses ([boxed] false: the cards only); on
/// its own ([boxed] true) it has its own yellow box and title. With the
/// [circleId], a missed task a tapped notification is about is brought
/// into view and tinted.
class MeasurementAttentionSection extends StatelessWidget {
  const MeasurementAttentionSection({
    super.key,
    required this.tasks,
    required this.readings,
    this.boxed = true,
    this.circleId,
  });

  final List<MeasurementOccurrence> tasks;
  final List<MeasurementReading> readings;
  final bool boxed;
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final clock = PatientClockScope.of(context);
    final missed = MeasurementAttention.missed(tasks);
    final outside = MeasurementAttention.outside(readings, clock);
    if (missed.isEmpty && outside.isEmpty) return const SizedBox.shrink();
    final Widget cards = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: measurementAttentionCards(
        context,
        missed,
        outside,
        now: clock.now(),
        circleId: circleId,
      ),
    );
    if (!boxed) return cards;
    return AttentionBox(
      title: context.tr('measurements.needs_attention'),
      count: missed.length + outside.length,
      child: cards,
    );
  }
}

/// The cards of the attention box, drawn as readings are in «السجل»:
/// «سجّل» and «تخطي» for a missed task (only «تخطي» once the next task of
/// its kind is due at [now], a wall time), «تابعتها» for a reading outside
/// its normal range, with its value, level and range.
List<Widget> measurementAttentionCards(
  BuildContext context,
  List<MeasurementOccurrence> missed,
  List<MeasurementReading> outside, {
  required DateTime now,
  String? circleId,
}) => <Widget>[
  for (final MeasurementOccurrence task in missed)
    MissedMeasurementCard(task: task, now: now, circleId: circleId),
  for (final MeasurementReading reading in outside)
    OutsideReadingCard(reading: reading),
];

/// Which readings «السجل» shows: every kind, or one of them.
enum MeasurementRecordFilter {
  all,
  glucose,
  bp;

  /// The kind this filter keeps; null for [all].
  MeasurementKind? get kind => switch (this) {
    all => null,
    glucose => MeasurementKind.glucose,
    bp => MeasurementKind.bp,
  };

  /// Whether a reading of [value] belongs in the list.
  bool keeps(MeasurementKind value) => kind == null || kind == value;

  /// The key of its words: «الكل», «سكر الدم», «ضغط الدم».
  String get labelKey => switch (this) {
    all => 'measurements.all',
    glucose => 'measurements.glucose',
    bp => 'measurements.bp',
  };
}

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

/// A reading outside its normal range in the attention box: its value,
/// level and range, and «تابعتها».
class OutsideReadingCard extends StatelessWidget {
  const OutsideReadingCard({super.key, required this.reading});

  final MeasurementReading reading;

  @override
  Widget build(BuildContext context) {
    return MeasurementAttentionCard(
      kind: reading.kind,
      title: ReadingTitles(reading: reading),
      status: ReadingValue(reading: reading),
      lines: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ReadingStatusPill(reading: reading),
        ),
        if (reading.range != null)
          Text(
            readingRangeText(context, reading),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
      actions: <Widget>[ReadingFollowUpButton(reading: reading)],
    );
  }
}

/// «تابعتها» under a reading outside its normal range, in the buttons every
/// task shares (TaskButtonRole): it records that someone followed it up.
class ReadingFollowUpButton extends StatelessWidget {
  const ReadingFollowUpButton({super.key, required this.reading});

  final MeasurementReading reading;

  @override
  Widget build(BuildContext context) => TaskButtonGrid(
    answer: TaskButton(
      role: TaskButtonRole.answer,
      icon: CupertinoIcons.checkmark,
      label: context.tr('measurements.follow_up'),
      onPressed: () => _followUp(context),
    ),
  );

  Future<void> _followUp(BuildContext context) async {
    final String? messageKey = await context
        .read<MeasurementReadingsCubit>()
        .followUp(reading);
    if (!context.mounted) return;
    if (messageKey == null) {
      AppToast.show(context, 'toast.follow_up_done');
    } else {
      showMeasurementMessage(context, messageKey);
    }
  }
}
