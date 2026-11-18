import 'dart:ui';

import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// The fill of a chip: faint on a dark ground, tinted when chosen, clear
/// for an unchosen choice, grey for a plain label.
Color simplifiedChipFill({
  required bool onDark,
  required bool selected,
  required bool choice,
}) => onDark
    ? SimplifiedColors.surface.withValues(alpha: .14)
    : selected
    ? SimplifiedColors.accentTint
    : choice
    ? SimplifiedColors.clear
    : SimplifiedColors.chip;
