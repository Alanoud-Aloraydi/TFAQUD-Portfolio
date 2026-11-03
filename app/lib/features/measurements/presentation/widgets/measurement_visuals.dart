import 'dart:math' as math;

import 'package:app/core/theme/app_semantic_colors.dart';

import 'dart:ui' as ui;

import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// RTL month chart: glucose columns and blood-pressure range capsules.
class MeasurementChart extends StatelessWidget {
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
  Widget build(BuildContext context) => SizedBox(
    height: 176,
    width: double.infinity,
    child: CustomPaint(
      painter: _MeasurementPainter(
        kind,
        readings,
        month,
        targetLow,
        targetHigh,
      ),
    ),
  );
}

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
      final at = reading.measuredAt?.toLocal();
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

/// A Saturday-first calendar with one cell per day and a count for repeats.
class MeasurementCalendar extends StatelessWidget {
  const MeasurementCalendar({
    super.key,
    required this.readings,
    required this.month,
  });

  final List<MeasurementReading> readings;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final lead = (month.weekday + 1) % 7;
    final today = DateUtils.dateOnly(DateTime.now());
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
      childAspectRatio: .9,
      children: [
        for (final day in const [6, 7, 1, 2, 3, 4, 5])
          Center(child: Text(context.tr('medications.weekday_short.$day'))),
        for (var index = 0; index < lead; index++) const SizedBox.shrink(),
        for (var day = 1; day <= days; day++) _cell(context, day, today),
      ],
    );
  }

  Widget _cell(BuildContext context, int day, DateTime today) {
    final date = DateTime(month.year, month.month, day);
    final values = readings.where((reading) {
      final at = reading.measuredAt?.toLocal();
      return at != null &&
          at.year == date.year &&
          at.month == date.month &&
          at.day == day;
    }).toList();
    final bad = values.any((reading) => reading.outsideTarget == true);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: values.isEmpty
            ? AppSemanticColors.surfacePlan
            : bad
            ? AppSemanticColors.surfaceAttention
            : AppSemanticColors.selectedSurface,
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: DateUtils.isSameDay(date, today)
            ? Border.all(color: AppSemanticColors.textPrimary, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$day', style: Theme.of(context).textTheme.labelSmall),
          Text(
            values.isEmpty ? '—' : values.first.valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (values.length > 1)
            Text(
              '${values.length}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
        ],
      ),
    );
  }
}
