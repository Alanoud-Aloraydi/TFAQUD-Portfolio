import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:flutter/material.dart';

/// A reading's level as the one status badge: «طبيعي ✓», «مرتفع ⚠».
class MeasurementLevelBadge extends StatelessWidget {
  const MeasurementLevelBadge({
    super.key,
    required this.level,
    required this.kind,
  });

  final MeasurementLevel level;
  final MeasurementKind kind;

  @override
  Widget build(BuildContext context) => StatusBadge(
    text: level.label(context, kind),
    tone: level.tone,
    icon: level.icon,
  );
}
