import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/widgets.dart';

/// How a ruler is drawn: how large, and in which colours. The default is
/// the detailed mode's, on a white sheet; the simplified mode draws the
/// same ruler larger, on its dark ground.
class RulerLook {
  const RulerLook({
    this.scale = 1,
    this.mark = AppSemanticColors.pickerMark,
    this.major = AppSemanticColors.textPrimary,
    this.minor = AppSemanticColors.borderControlBase,
    this.label = AppSemanticColors.textSupporting,
  });

  /// Every size of the ruler is multiplied by it: its height, the room of
  /// one mark, the marks themselves and the words under them.
  final double scale;

  /// The fixed mark over the number chosen.
  final Color mark;

  /// A long mark, and a short one between two long ones.
  final Color major;
  final Color minor;

  /// The words under a long mark.
  final Color label;
}
