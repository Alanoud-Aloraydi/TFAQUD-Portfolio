import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/measurements/domain/chart_target.dart';
import 'package:flutter/material.dart';

/// The colours of a month chart, read by what draws it and by its legend,
/// so the legend always shows the colours the chart uses.
abstract final class ChartColors {
  /// A reading in its normal range.
  static const Color reading = AppSemanticColors.chartInk;

  /// A reading outside its normal range.
  static const Color outside = AppSemanticColors.statusError;

  /// The line that joins a month of glucose readings.
  static final Color line = reading.withValues(alpha: .45);

  static const Color _band = AppSemanticColors.surfaceSuccess;
  static final Color _innerBand = AppSemanticColors.statusSuccess.withValues(
    alpha: .18,
  );

  /// The shade of a normal band; an inner one is darker so both show.
  static Color band(ChartBand band) => band.inner ? _innerBand : _band;
}
