import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/display/weekday_strip.dart';
import 'package:app/core/widgets/layout/plan_info_box.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The times a measurement plan asks for, each with its condition (when the
/// plan has several), and the days of the week it repeats on.
class MeasurementPlanTimesBox extends StatelessWidget {
  const MeasurementPlanTimesBox({super.key, required this.version});

  final MeasurementVersion version;

  @override
  Widget build(BuildContext context) {
    final bool several = version.readingTimes.length > 1;
    return PlanInfoBox(
      child: Column(
        children: <Widget>[
          for (final MeasurementTime reading in version.readingTimes)
            Row(
              children: <Widget>[
                Text(clockText(reading.time)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    several && reading.measurementState != null
                        ? context.tr(
                            'measurements.condition.${reading.measurementState}',
                          )
                        : context.tr('measurements.one_reading'),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          WeekdayStrip(days: version.weekdays),
        ],
      ),
    );
  }
}
