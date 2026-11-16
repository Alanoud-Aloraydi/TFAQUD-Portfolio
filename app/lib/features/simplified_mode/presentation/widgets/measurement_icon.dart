import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:flutter/material.dart';

/// The icon of a measurement kind, as the detailed mode's measurement rows
/// draw it: a drop for glucose, a heart for blood pressure.
IconData measurementIcon(MeasurementKind kind) =>
    kind == MeasurementKind.bp ? AppIcons.heart : AppIcons.drop;
