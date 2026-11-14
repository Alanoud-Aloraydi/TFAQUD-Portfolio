import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Pencil badge pinned to a photo's bottom corner, marking it editable.
/// Place inside a [Stack] (with `clipBehavior: Clip.none` over a circular
/// photo, since the badge sits partly outside the circle) alongside the
/// photo it edits.
class PhotoEditBadge extends StatelessWidget {
  const PhotoEditBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const PositionedDirectional(
      end: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppSemanticColors.surfaceContent,
          shape: CircleBorder(
            side: BorderSide(color: AppSemanticColors.borderSubtle),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xs),
          child: Icon(AppIcons.pencil, size: 16),
        ),
      ),
    );
  }
}
