import 'dart:math' as math;

import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/glass_menu_entry.dart';
import 'package:flutter/material.dart';

/// Where the open glass menu sits and how big it is, for the room the page
/// leaves it.
class GlassMenuLayout {
  const GlassMenuLayout({
    required this.row,
    required this.edge,
    required this.height,
    required this.width,
    required this.target,
  });

  /// Works out the menu of [sections] opened from [anchor] inside
  /// [constraints].
  factory GlassMenuLayout.of(
    BuildContext context,
    BoxConstraints constraints,
    Rect anchor,
    List<List<GlassMenuEntry>> sections,
  ) {
    final double row = rowHeight(context);
    final int rows = sections.fold(
      0,
      (int n, List<GlassMenuEntry> s) => n + s.length,
    );
    final double edge = MediaQuery.highContrastOf(context) ? 3 : 1;
    final double height =
        2 * AppSpacing.sm +
        rows * row +
        (sections.length - 1) * _separator +
        edge;
    final double room = constraints.maxWidth - 2 * AppSpacing.lg;
    final double width = math.min(math.max(anchor.width + 96, _minWidth), room);
    final double left = (anchor.center.dx - width / 2).clamp(
      AppSpacing.lg,
      constraints.maxWidth - AppSpacing.lg - width,
    );
    final double bottomInset =
        MediaQuery.paddingOf(context).bottom + AppSpacing.lg;
    final double maxTop = math.max(
      AppSpacing.lg,
      constraints.maxHeight - bottomInset - height,
    );
    // Open downward from the anchor when there is room below it;
    // otherwise flip to grow upward so low anchors never clip rows
    // off the bottom of the screen.
    final double top = anchor.top > maxTop
        ? math.max(AppSpacing.lg, anchor.bottom - height)
        : anchor.top;
    return GlassMenuLayout(
      row: row,
      edge: edge,
      height: height,
      width: width,
      target: Rect.fromLTWH(left, math.min(top, maxTop), width, height),
    );
  }

  static const double _minWidth = 248;
  static const double _separator = 1 + 2 * AppSpacing.xs;

  /// Height of one row: at least 48, more with larger text.
  static double rowHeight(BuildContext context) => math.max(
    AppSizes.touch + AppSpacing.xs,
    MediaQuery.textScalerOf(context).scale(28) + 2 * AppSpacing.sm,
  );

  final double row;

  /// The thickness of the menu's bottom edge, thicker in high contrast.
  final double edge;
  final double height;
  final double width;

  /// The menu's rectangle once fully open.
  final Rect target;
}
