import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/measurements/domain/entities/chart_target.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_loading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_loading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_section.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_calendar.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_readings_history.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_status.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// What «السجل»'s measurements show for [state] under the filter and the
/// month: the first read, why it failed with [onRetry], the empty note with
/// [onAddReading], or a chart for each kind that has a reading in [month]
/// and the readings under them. A plan alone draws no chart.
List<Widget> measurementRecordContent(
  MeasurementReadingsState state, {
  required String circleId,
  required CalendarMonth month,
  required MeasurementRecordFilter filter,
  required VoidCallback onRetry,
  VoidCallback? onAddReading,
}) {
  if (state.status == MeasurementLoadStatus.initial ||
      (state.status == MeasurementLoadStatus.loading &&
          state.readings.isEmpty)) {
    return const <Widget>[LoadingNote()];
  }
  if (state.status == MeasurementLoadStatus.failure) {
    return <Widget>[
      RetryView(
        messageKey: state.errorKey ?? 'error.unknown',
        onRetry: onRetry,
      ),
    ];
  }
  final List<MeasurementReading> kept = <MeasurementReading>[
    for (final MeasurementReading r in state.readings)
      if (filter.keeps(r.kind)) r,
  ];
  if (kept.isEmpty) {
    return <Widget>[MeasurementRecordEmpty(onAdd: onAddReading)];
  }
  return <Widget>[
    for (final MeasurementKind kind in MeasurementKind.values)
      if (kept.any((r) => r.kind == kind && r.outcome == 'read')) ...<Widget>[
        MeasurementChartCard(
          kind: kind,
          readings: <MeasurementReading>[
            for (final MeasurementReading r in kept)
              if (r.kind == kind && r.outcome == 'read') r,
          ],
          month: month,
          circleId: circleId,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    const SizedBox(height: AppSpacing.md),
    MeasurementReadingsHistory(circleId: circleId, readings: kept),
  ];
}

/// «السجل»'s readings when the month has none under the filter: the note,
/// with «تسجيل قراءة» for someone who may record one, as «الخطة» offers
/// its own add.
class MeasurementRecordEmpty extends StatelessWidget {
  const MeasurementRecordEmpty({super.key, this.onAdd});

  /// Opens the reading sheet; null hides the action.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => EmptyStateNote.section(
    context.tr('measurements.no_records'),
    actionLabel: onAdd == null
        ? null
        : context.tr('measurements.record_reading'),
    onAction: onAdd,
  );
}

/// A month of one kind of reading: the latest value, the count, and a switch
/// between the chart and the calendar.
class MeasurementChartCard extends StatefulWidget {
  const MeasurementChartCard({
    super.key,
    required this.kind,
    required this.readings,
    required this.month,
    required this.circleId,
  });

  final MeasurementKind kind;
  final List<MeasurementReading> readings;
  final CalendarMonth month;
  final String circleId;

  @override
  State<MeasurementChartCard> createState() => _MeasurementChartCardState();
}

class _MeasurementChartCardState extends State<MeasurementChartCard> {
  bool _calendar = false;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MeasurementChartCardHeader(
              kind: widget.kind,
              latest: widget.readings.firstOrNull,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(readingCountText(context, widget.readings)),
            const SizedBox(height: AppSpacing.sm),
            MeasurementChartSwitch(
              calendar: _calendar,
              onChanged: (value) => setState(() => _calendar = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            MeasurementMonthView(card: widget, calendar: _calendar),
          ],
        ),
      ),
    );
  }
}

/// How many [readings] a month has and how many of them are outside their
/// range, or that it has none.
String readingCountText(
  BuildContext context,
  List<MeasurementReading> readings,
) => readings.isEmpty
    ? context.tr('measurements.no_readings')
    : context.tr(
        'measurements.reading_count',
        args: <String>[
          '${readings.length}',
          '${readings.where((r) => r.outsideTarget == true).length}',
        ],
      );

/// A month [card]'s readings as the chart or, with [calendar], the
/// calendar, the one fading into the other.
class MeasurementMonthView extends StatelessWidget {
  const MeasurementMonthView({
    super.key,
    required this.card,
    required this.calendar,
  });

  final MeasurementChartCard card;
  final bool calendar;

  @override
  Widget build(BuildContext context) {
    final ChartTarget target = ChartTarget.of(
      kind: card.kind,
      readings: card.readings,
    );
    return AnimatedSwitcher(
      duration: AppMotion.branchEnterDuration,
      reverseDuration: AppMotion.branchExitDuration,
      switchInCurve: AppMotion.branchEnter,
      switchOutCurve: AppMotion.easeIn,
      child: KeyedSubtree(
        key: ValueKey(calendar),
        child: calendar
            ? MeasurementCalendar(
                readings: card.readings,
                month: card.month,
                circleId: card.circleId,
              )
            : MeasurementChart(
                kind: card.kind,
                readings: card.readings,
                month: card.month,
                circleId: card.circleId,
                target: target,
              ),
      ),
    );
  }
}

/// The kind of reading a month card is about, and its [latest] value.
class MeasurementChartCardHeader extends StatelessWidget {
  const MeasurementChartCardHeader({
    super.key,
    required this.kind,
    required this.latest,
  });

  final MeasurementKind kind;
  final MeasurementReading? latest;

  @override
  Widget build(BuildContext context) {
    final bool glucose = kind == MeasurementKind.glucose;
    return Row(
      children: <Widget>[
        Icon(glucose ? CupertinoIcons.drop : CupertinoIcons.heart),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.tr(glucose ? 'measurements.glucose' : 'measurements.bp'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (latest case final MeasurementReading reading)
          ReadingValue(reading: reading),
      ],
    );
  }
}
