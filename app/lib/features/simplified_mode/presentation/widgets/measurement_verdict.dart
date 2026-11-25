import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:flutter/material.dart';

/// A reading's level in the words and the icon every page uses for it.
class MeasurementVerdict {
  const MeasurementVerdict(this.label, this.level);

  final String label;
  final MeasurementLevel level;
}

/// The icon of a measurement kind, as the detailed mode's measurement rows
/// draw it: a drop for glucose, a heart for blood pressure.
IconData measurementIcon(MeasurementKind kind) =>
    kind == MeasurementKind.bp ? CareIcons.heart : CareIcons.drop;
