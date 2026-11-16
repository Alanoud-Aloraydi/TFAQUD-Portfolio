import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

// 44 everywhere, the smallest target a finger finds reliably, and
// the one layout that asks the patient to act is no place to save
// ten pixels.
const double _height = AppSizes.touch;

/// The two answers of the compact dose controls.
ButtonStyle doseCompactFilledStyle() => FilledButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  minimumSize: const Size(0, _height),
);

/// The same size for the quieter pair, without the filled button's
/// colours: styleFrom carries a background, so the two answers would
/// stop looking like the answers.
ButtonStyle doseCompactTextStyle() => TextButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  minimumSize: const Size(0, _height),
);
