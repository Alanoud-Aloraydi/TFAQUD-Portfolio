import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// RTL month chart: glucose columns and blood-pressure range capsules.
class MeasurementChart extends StatefulWidget {
  const MeasurementChart({
    super.key,
    required this.kind,
    required this.readings,
    required this.month,
    this.targetLow,
    this.targetHigh,
  });

  final MeasurementKind kind;
  final List<MeasurementReading> readings;
  final DateTime month;
  final int? targetLow;
  final int? targetHigh;

  @override
  State<MeasurementChart> createState() => _MeasurementChartState();
}

class _MeasurementChartState extends State<MeasurementChart> {
  MeasurementReading? _selected;

  @override
  void didUpdateWidget(MeasurementChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected != null &&
        !widget.readings.any((item) => item.id == _selected!.id)) {
      _selected = null;
    }
  }

  void _select(TapDownDetails details, double width) {
    final days = DateUtils.getDaysInMonth(
      widget.month.year,
      widget.month.month,
    );
    final slot = (width - 33) / days;
    final values = widget.readings
        .expand(
          (reading) => [
            if (reading.valueOne != null) reading.valueOne!,
            if (reading.valueTwo != null) reading.valueTwo!,
          ],
        )
        .toList();
    final top = math.max(
      180,
      math.max(
            widget.targetHigh ?? 0,
            values.isEmpty ? 0 : values.reduce(math.max),
          ) +
          20,
    );
    double y(int value) => 152 - value / top * 136;
    MeasurementReading? nearest;
    var distance = double.infinity;
    for (var day = 1; day <= days; day++) {
      final dayReadings = widget.readings.where((reading) {
        final at = reading.measuredAt;
        if (at == null) return false;
        final local = riyadhNow(at);
        return local.year == widget.month.year &&
            local.month == widget.month.month &&
            local.day == day;
      }).toList();
      for (var index = 0; index < dayReadings.length; index++) {
        final reading = dayReadings[index];
        final barWidth = math.max(
          2.0,
          math.min(8.0, (slot - 2) / dayReadings.length - 1),
        );
        final center =
            width -
            29 -
            (day - .5) * slot +
            (index - (dayReadings.length - 1) / 2) * (barWidth + 1);
        final first = y(reading.valueOne!);
        final second = y(
          widget.kind == MeasurementKind.glucose ? 0 : reading.valueTwo!,
        );
        final gap = (center - details.localPosition.dx).abs();
        if (gap < distance &&
            gap <= math.max(12, slot / 2) &&
            details.localPosition.dy >= math.min(first, second) - 8 &&
            details.localPosition.dy <= math.max(first, second) + 8) {
          nearest = reading;
          distance = gap;
        }
      }
    }
    setState(() => _selected = nearest);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _select(details, constraints.maxWidth),
          child: SizedBox(
            height: 176,
            child: CustomPaint(
              painter: _MeasurementPainter(
                widget.kind,
                widget.readings,
                widget.month,
                widget.targetLow,
                widget.targetHigh,
              ),
            ),
          ),
        ),
      ),
      if (_selected case final reading?) ...[
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppSemanticColors.surfaceContent,
            border: Border.all(color: AppSemanticColors.borderSubtle),
            borderRadius: BorderRadius.circular(AppRadius.s),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              '${context.tr(widget.kind == MeasurementKind.glucose ? 'measurements.glucose' : 'measurements.bp')} '
              '${reading.valueText} · '
              '${_readingDateTime(reading.measuredAt!)} · '
              '${context.tr(reading.outsideTarget == true
                  ? 'measurements.outside_target'
                  : reading.outsideTarget == false
                  ? 'measurements.in_target'
                  : 'measurements.without_target')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          _ChartKey(
            AppSemanticColors.textPrimary,
            context.tr('measurements.chart_legend_reading'),
          ),
          _ChartKey(
            AppSemanticColors.statusWarning,
            context.tr('measurements.chart_legend_outside'),
          ),
          if (widget.targetLow != null && widget.targetHigh != null)
            _ChartKey(
              widget.kind == MeasurementKind.glucose
                  ? AppSemanticColors.selectedSurface
                  : AppSemanticColors.statusSuccess,
              context.tr(
                widget.kind == MeasurementKind.glucose
                    ? 'measurements.chart_legend_glucose_target'
                    : 'measurements.chart_legend_bp_target',
              ),
            ),
        ],
      ),
    ],
  );

  String _readingDateTime(DateTime instant) {
    final at = riyadhNow(instant);
    return '${at.day}/${at.month} '
        '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';
  }
}

class _ChartKey extends StatelessWidget {
  const _ChartKey(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: const SizedBox(width: 12, height: 5),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

/// Draws measurement trends and target ranges.
class _MeasurementPainter extends CustomPainter {
  _MeasurementPainter(
    this.kind,
    this.readings,
    this.month,
    this.targetLow,
    this.targetHigh,
  );

  final MeasurementKind kind;
  final List<MeasurementReading> readings;
  final DateTime month;
  final int? targetLow;
  final int? targetHigh;

  @override
  void paint(Canvas canvas, Size size) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final values = readings
        .expand(
          (reading) => [
            if (reading.valueOne != null) reading.valueOne!,
            if (reading.valueTwo != null) reading.valueTwo!,
          ],
        )
        .toList();
    final topValue = math
        .max(
          180,
          math.max(
                targetHigh ?? 0,
                values.isEmpty ? 0 : values.reduce(math.max),
              ) +
              20,
        )
        .toDouble();
    const chartTop = 16.0;
    final chartBottom = size.height - 24;
    const labelWidth = 29.0;
    const chartLeft = 4.0;
    double y(num value) =>
        chartBottom - (value / topValue) * (chartBottom - chartTop);
    final slot = (size.width - labelWidth - chartLeft) / days;
    double x(int day) => size.width - labelWidth - (day - .5) * slot;

    if (targetLow != null && targetHigh != null) {
      if (kind == MeasurementKind.glucose) {
        canvas.drawRect(
          Rect.fromLTRB(
            chartLeft,
            y(targetHigh!),
            size.width - labelWidth,
            y(targetLow!),
          ),
          Paint()..color = AppSemanticColors.selectedSurface,
        );
      } else {
        for (final limit in [targetLow!, targetHigh!]) {
          canvas.drawLine(
            Offset(chartLeft, y(limit)),
            Offset(size.width - labelWidth, y(limit)),
            Paint()
              ..color = AppSemanticColors.statusSuccess
              ..strokeWidth = 1.5,
          );
        }
      }
    }
    for (final tick in [0, (topValue / 2).round(), topValue.round()]) {
      canvas.drawLine(
        Offset(chartLeft, y(tick)),
        Offset(size.width - labelWidth, y(tick)),
        Paint()..color = AppSemanticColors.borderSubtle,
      );
      _label(
        canvas,
        '$tick',
        Offset(size.width - labelWidth + 3, y(tick)),
        AppSemanticColors.textSupporting,
      );
    }
    final byDay = <int, List<MeasurementReading>>{};
    for (final reading in readings) {
      final at = reading.measuredAt == null
          ? null
          : riyadhNow(reading.measuredAt);
      if (at == null || at.year != month.year || at.month != month.month) {
        continue;
      }
      byDay.putIfAbsent(at.day, () => []).add(reading);
    }
    for (final entry in byDay.entries) {
      final width = math.max(
        2.0,
        math.min(8.0, (slot - 2) / entry.value.length - 1),
      );
      for (var index = 0; index < entry.value.length; index++) {
        final reading = entry.value[index];
        final center =
            x(entry.key) + (index - (entry.value.length - 1) / 2) * (width + 1);
        final color = reading.outsideTarget == true
            ? AppSemanticColors.statusWarning
            : AppSemanticColors.textPrimary;
        final first = reading.valueOne!;
        final second = kind == MeasurementKind.glucose ? 0 : reading.valueTwo!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              center - width / 2,
              y(first),
              center + width / 2,
              y(second),
            ),
            Radius.circular(width / 2),
          ),
          Paint()..color = color,
        );
      }
    }
    for (final day in [1, 8, 15, 22, 29]) {
      if (day > days) continue;
      _label(
        canvas,
        '$day',
        Offset(x(day) - 3, size.height - 9),
        AppSemanticColors.textSupporting,
      );
    }
  }

  void _label(Canvas canvas, String text, Offset at, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, color: color),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(at.dx, at.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MeasurementPainter oldDelegate) =>
      oldDelegate.readings != readings ||
      oldDelegate.month != month ||
      oldDelegate.targetLow != targetLow ||
      oldDelegate.targetHigh != targetHigh;
}

/// Compact Saturday-first calendar with readings shown below the selected day.
class MeasurementCalendar extends StatefulWidget {
  const MeasurementCalendar({
    super.key,
    required this.readings,
    required this.month,
  });

  final List<MeasurementReading> readings;
  final DateTime month;

  @override
  State<MeasurementCalendar> createState() => _MeasurementCalendarState();
}

class _MeasurementCalendarState extends State<MeasurementCalendar> {
  int? _selectedDay;

  @override
  void didUpdateWidget(MeasurementCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month.year != widget.month.year ||
        oldWidget.month.month != widget.month.month) {
      _selectedDay = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(
      widget.month.year,
      widget.month.month,
    );
    final lead = (widget.month.weekday + 1) % 7;
    final today = riyadhToday();
    final rows = ((lead + days) / 7).ceil();
    final selected = _selectedDay;
    final selectedReadings = selected == null
        ? <MeasurementReading>[]
        : _readingsOn(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final day in const [6, 7, 1, 2, 3, 4, 5])
              Expanded(
                child: Center(
                  child: Text(
                    context.tr('medications.weekday_short.$day'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _dayCell(
                        context,
                        row * 7 + column - lead + 1,
                        today,
                        days,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$selected ${context.tr('circles.months.${widget.month.month}')}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (selectedReadings.isEmpty)
            Text(context.tr('measurements.no_readings'))
          else
            for (final reading in selectedReadings)
              Text(
                '${reading.valueText} · '
                '${_readingTime(riyadhNow(reading.measuredAt!))}',
              ),
        ],
      ],
    );
  }

  List<MeasurementReading> _readingsOn(int day) =>
      widget.readings.where((reading) {
        final at = reading.measuredAt == null
            ? null
            : riyadhNow(reading.measuredAt);
        return at != null &&
            at.year == widget.month.year &&
            at.month == widget.month.month &&
            at.day == day;
      }).toList();

  String _readingTime(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  Widget _dayCell(BuildContext context, int day, DateTime today, int days) =>
      day < 1 || day > days
      ? const SizedBox(height: AppSizes.touch)
      : _cell(context, day, today);

  Widget _cell(BuildContext context, int day, DateTime today) {
    final date = DateTime(widget.month.year, widget.month.month, day);
    final values = _readingsOn(day);
    final bad = values.any((reading) => reading.outsideTarget == true);
    final selected = _selectedDay == day;
    return Semantics(
      button: true,
      selected: selected,
      label: '$day · ${values.length}',
      child: InkWell(
        onTap: () => setState(() => _selectedDay = day),
        borderRadius: BorderRadius.circular(AppRadius.s),
        child: Container(
          height: AppSizes.touch,
          decoration: BoxDecoration(
            color: selected
                ? AppSemanticColors.selectedSurface
                : bad
                ? AppSemanticColors.surfaceAttention
                : AppSemanticColors.surfaceContent,
            borderRadius: BorderRadius.circular(AppRadius.s),
            border: Border.all(
              color: selected || DateUtils.isSameDay(date, today)
                  ? AppSemanticColors.textPrimary
                  : AppSemanticColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$day', style: Theme.of(context).textTheme.labelSmall),
              if (values.isNotEmpty)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bad
                        ? AppSemanticColors.statusWarning
                        : AppSemanticColors.statusSuccess,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
