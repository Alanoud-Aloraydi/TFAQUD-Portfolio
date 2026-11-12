import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// Where a reading stands against its target: in, outside, or no target.
/// The icon and the words say it, so colour is never the only signal.
class ReadingStatusPill extends StatelessWidget {
  const ReadingStatusPill({super.key, required this.reading});

  final MeasurementReading reading;

  @override
  Widget build(BuildContext context) {
    final bool? outside = reading.outsideTarget;
    if (outside == true) {
      return StatusBadge(
        icon: CupertinoIcons.exclamationmark_triangle,
        text: context.tr('measurements.outside_target'),
        tone: StatusTone.attention,
      );
    }
    return StatusBadge(
      icon: outside == false
          ? CupertinoIcons.checkmark_circle
          : CupertinoIcons.minus_circle,
      text: context.tr(
        outside == false
            ? 'measurements.in_target'
            : 'measurements.without_target',
      ),
      tone: outside == false ? StatusTone.success : StatusTone.neutral,
    );
  }
}
