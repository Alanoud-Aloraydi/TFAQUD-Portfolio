import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The measurements that need attention: a missed measurement, and a reading
/// of today outside its target that nobody followed up yet.
///
/// On «اليوم» they sit inside the one «يحتاج انتباهك» box with the doses
/// ([boxed] false: the cards only). On its own ([boxed] true) it has its own
/// yellow box and title.
class MeasurementAttentionSection extends StatelessWidget {
  const MeasurementAttentionSection({
    super.key,
    required this.tasks,
    required this.readings,
    this.boxed = true,
  });

  final List<MeasurementOccurrence> tasks;
  final List<MeasurementReading> readings;
  final bool boxed;

  /// How many cards it shows.
  static int count(
    List<MeasurementOccurrence> tasks,
    List<MeasurementReading> readings,
  ) => _missed(tasks).length + _outside(readings).length;

  static List<MeasurementOccurrence> _missed(
    List<MeasurementOccurrence> tasks,
  ) => tasks.where((item) => item.status == MeasurementStatus.missed).toList();

  static List<MeasurementReading> _outside(List<MeasurementReading> readings) =>
      readings
          .where(
            (item) =>
                item.outsideTarget == true &&
                item.followedUpAt == null &&
                item.measuredAt != null &&
                DateUtils.isSameDay(riyadhNow(item.measuredAt), riyadhNow()),
          )
          .toList();

  @override
  Widget build(BuildContext context) {
    final missed = _missed(tasks);
    final outside = _outside(readings);
    if (missed.isEmpty && outside.isEmpty) return const SizedBox.shrink();
    if (!boxed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _cards(context, missed, outside),
      );
    }
    return AttentionBox(
      title: context.tr('measurements.needs_attention'),
      count: missed.length + outside.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _cards(context, missed, outside),
      ),
    );
  }

  List<Widget> _cards(
    BuildContext context,
    List<MeasurementOccurrence> missed,
    List<MeasurementReading> outside,
  ) => [
    for (final task in missed) ...[
      _attentionCard(
        context,
        title:
            '${_title(context, task.kind)} · '
            '${_time(context, task.time)}',
        subtitle: context.tr('measurements.not_recorded'),
        actions: [
          FilledButton(
            onPressed: () => _record(context, task),
            child: Text(context.tr('measurements.record_reading')),
          ),
          TextButton(
            onPressed: () => context.read<MeasurementTasksCubit>().skip(task),
            child: Text(context.tr('measurements.skip')),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
    ],
    for (final reading in outside) ...[
      _attentionCard(
        context,
        title:
            '${_title(context, reading.kind)} '
            '${reading.valueText}',
        subtitle: context.tr('measurements.outside_target'),
        actions: [
          TextButton(
            onPressed: () =>
                context.read<MeasurementReadingsCubit>().followUp(reading),
            child: Text(context.tr('measurements.follow_up')),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
    ],
  ];

  Widget _attentionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> actions,
  }) => TodayRowCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.sm, children: actions),
      ],
    ),
  );

  Future<void> _record(BuildContext context, MeasurementOccurrence task) async {
    final saved = await showMeasurementReadingSheet(context, occurrence: task);
    if (saved && context.mounted) {
      context.read<MeasurementTasksCubit>().reload();
    }
  }
}

/// Displays the measurement task row UI.
class MeasurementTaskRow extends StatelessWidget {
  const MeasurementTaskRow({
    super.key,
    required this.task,
    required this.now,
    required this.circleId,
  });

  final MeasurementOccurrence task;
  final DateTime now;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final resolved =
        task.status != MeasurementStatus.upcoming &&
        task.status != MeasurementStatus.due &&
        task.status != MeasurementStatus.missed;
    final canRecord = canRecordOccurrence(
      resolved: resolved,
      scheduledAt: riyadhScheduledAt(task.scheduledOn, task.time),
      now: now,
    );
    final status = switch (task.status) {
      MeasurementStatus.read => 'measurements.read',
      MeasurementStatus.readLate => 'measurements.read_late',
      MeasurementStatus.skipped => 'measurements.skipped',
      MeasurementStatus.missed => 'measurements.missed',
      MeasurementStatus.due => 'measurements.due',
      MeasurementStatus.upcoming => 'measurements.upcoming',
    };
    return TodayRowCard(
      isAttention: task.status == MeasurementStatus.missed,
      child: Column(
        children: [
          Row(
            children: [
              Text(_time(context, task.time)),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                task.kind == MeasurementKind.glucose
                    ? CupertinoIcons.drop
                    : CupertinoIcons.heart,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(context, task.kind),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (task.conditions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CompactStatusBadge(
                          text: conditionsText(context, task.conditions),
                          background: AppSemanticColors.surfaceContent,
                          foreground: AppSemanticColors.textSupporting,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              CompactStatusBadge(
                text: context.tr(status),
                background: task.status == MeasurementStatus.missed
                    ? Theme.of(context).colorScheme.errorContainer
                    : AppSemanticColors.surfaceContent,
                foreground: task.status == MeasurementStatus.missed
                    ? AppSemanticColors.statusError
                    : AppSemanticColors.textSupporting,
              ),
            ],
          ),
          if (task.record case final record?)
            if (record.outcome == 'read') ...[
              Text(
                record.valueText,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                context.tr(
                  'measurements.recorded_at',
                  args: [_time(context, _hhmm(riyadhNow(record.recordedAt)))],
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (record.recordedByName case final name?) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PersonPhoto(
                      name: name,
                      photoPath: personPhotoPath(
                        circleId,
                        record.recordedByAccountId,
                      ),
                      avatarCode: record.recordedByAvatarCode,
                      size: AppSizes.iconSmall,
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    Text(name, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ],
          if (canRecord)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        minimumSize: const Size(0, 34),
                      ),
                      onPressed: () async {
                        final saved = await showMeasurementReadingSheet(
                          context,
                          occurrence: task,
                        );
                        if (saved && context.mounted) {
                          context.read<MeasurementTasksCubit>().reload();
                        }
                      },
                      icon: const Icon(CupertinoIcons.checkmark, size: 16),
                      label: Text(context.tr('measurements.record_reading')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                    ),
                    onPressed: () =>
                        context.read<MeasurementTasksCubit>().skip(task),
                    icon: const Icon(CupertinoIcons.minus_circle, size: 16),
                    label: Text(context.tr('measurements.skip')),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _title(BuildContext context, MeasurementKind kind) => context.tr(
  kind == MeasurementKind.glucose ? 'measurements.glucose' : 'measurements.bp',
);

String _time(BuildContext context, String value) {
  final parts = value.split(':');
  final hour24 = int.parse(parts[0]);
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour:${parts[1]} '
      '${context.tr(hour24 < 12 ? 'common.am' : 'common.pm')}';
}

String _hhmm(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}';
