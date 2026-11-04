import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceAttention,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: AppSemanticColors.borderAttention),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle,
                  color: AppSemanticColors.statusWarning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.tr('measurements.needs_attention'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._cards(context, missed, outside),
          ],
        ),
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
              onPressed: () =>
                  context.read<MeasurementTasksCubit>().skip(task),
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
              onPressed: () => context
                  .read<MeasurementReadingsCubit>()
                  .followUp(reading),
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
  }) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppSemanticColors.surfaceContent,
      borderRadius: BorderRadius.circular(AppRadius.field),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: AppSpacing.sm, children: actions),
        ],
      ),
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
  const MeasurementTaskRow({super.key, required this.task});

  final MeasurementOccurrence task;

  @override
  Widget build(BuildContext context) {
    final pending =
        task.status == MeasurementStatus.upcoming ||
        task.status == MeasurementStatus.due ||
        task.status == MeasurementStatus.missed;
    final status = switch (task.status) {
      MeasurementStatus.read => 'measurements.read',
      MeasurementStatus.readLate => 'measurements.read_late',
      MeasurementStatus.skipped => 'measurements.skipped',
      MeasurementStatus.missed => 'measurements.missed',
      MeasurementStatus.due => 'measurements.due',
      MeasurementStatus.upcoming => 'measurements.upcoming',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: task.status == MeasurementStatus.missed
            ? Border.all(color: AppSemanticColors.statusError)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                      if (task.glucoseContext != null)
                        Text(
                          context.tr(
                            'measurements.context.${task.glucoseContext}',
                          ),
                        ),
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
            if (task.record?.outcome == 'read')
              Text(
                task.record!.valueText,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            if (pending)
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      final saved = await showMeasurementReadingSheet(
                        context,
                        occurrence: task,
                      );
                      if (saved && context.mounted) {
                        context.read<MeasurementTasksCubit>().reload();
                      }
                    },
                    child: Text(context.tr('measurements.record_reading')),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<MeasurementTasksCubit>().skip(task),
                    child: Text(context.tr('measurements.skip')),
                  ),
                ],
              ),
          ],
        ),
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
