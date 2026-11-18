import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «قراءتك» with the badge of the [level] the value typed or shown is in.
class NormalRangeYourReading extends StatelessWidget {
  const NormalRangeYourReading({
    super.key,
    required this.level,
    required this.kind,
  });

  final MeasurementLevel level;
  final MeasurementKind kind;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        context.tr('measurements.your_reading'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(width: AppSpacing.sm),
      MeasurementLevelBadge(level: level, kind: kind),
    ],
  );
}
