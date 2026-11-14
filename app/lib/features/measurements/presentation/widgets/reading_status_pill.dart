import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// Where a reading falls in its normal range: «طبيعي», «منخفض», «أعلى من
/// الطبيعي», «مرتفع». A reading from a server before fixed ranges says in
/// or outside its old target, or none. The icon and the words say it, so
/// colour is never the only signal.
class ReadingStatusPill extends StatelessWidget {
  const ReadingStatusPill({super.key, required this.reading});

  final MeasurementReading reading;

  @override
  Widget build(BuildContext context) {
    if (reading.level case final level?) {
      return MeasurementLevelBadge(level: level, kind: reading.kind);
    }
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
