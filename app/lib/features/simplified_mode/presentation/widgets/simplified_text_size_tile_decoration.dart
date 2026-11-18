import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';
import 'package:flutter/material.dart';

/// The box of a text-size tile: tinted with a thick ink edge when chosen,
/// plain with a thin grey edge otherwise.
BoxDecoration simplifiedTextSizeTileDecoration({required bool selected}) {
  return BoxDecoration(
    color: selected ? SimplifiedColors.accentTint : SimplifiedColors.surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: selected ? SimplifiedColors.ink : SimplifiedColors.disabled,
      width: selected ? 3 : 2,
    ),
  );
}
