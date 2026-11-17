import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// The frame of a circle page that draws its own top row in place of an app
/// bar: the sides, a little air at the top, and nothing at the bottom, where
/// the list scrolls to the edge.
const EdgeInsets pageFramePadding = EdgeInsets.fromLTRB(
  AppSpacing.lg,
  AppSpacing.sm,
  AppSpacing.lg,
  0,
);
