import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

export 'package:app/features/measurements/presentation/widgets/normal_band_text.dart';
export 'package:app/features/measurements/presentation/widgets/normal_range_value.dart';

/// How each level reads, looks and sounds, so a level is the same on every
/// page: words and an icon, never colour alone.
extension MeasurementLevelLook on MeasurementLevel {
  /// «منخفض», «طبيعي», «أعلى من الطبيعي» (glucose) or «طبيعي مرتفع» (blood
  /// pressure), «مرتفع».
  String label(BuildContext context, MeasurementKind kind) =>
      context.tr(switch (this) {
        MeasurementLevel.low => 'measurements.level.low',
        MeasurementLevel.normal => 'measurements.level.normal',
        MeasurementLevel.elevated =>
          kind == MeasurementKind.bp
              ? 'measurements.level.elevated_bp'
              : 'measurements.level.elevated_glucose',
        MeasurementLevel.high => 'measurements.level.high',
      });

  StatusTone get tone => switch (this) {
    MeasurementLevel.normal => StatusTone.success,
    MeasurementLevel.high => StatusTone.danger,
    MeasurementLevel.low || MeasurementLevel.elevated => StatusTone.attention,
  };

  IconData get icon => switch (this) {
    MeasurementLevel.low => ArrowIcons.caretDown,
    MeasurementLevel.normal => ActionIcons.check,
    MeasurementLevel.elevated => ArrowIcons.caretUp,
    MeasurementLevel.high => NoticeIcons.warning,
  };

  /// The fill of this level's part of the scale: calm below, green in the
  /// range, warm above, red when high.
  Color get scaleFill => switch (this) {
    MeasurementLevel.low => AppSemanticColors.borderPlan,
    MeasurementLevel.normal => AppSemanticColors.selectedSurface,
    MeasurementLevel.elevated => AppSemanticColors.surfaceAttention,
    MeasurementLevel.high => AppSemanticColors.surfaceDanger,
  };
}

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
