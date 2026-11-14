import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_surface.dart';
import 'package:flutter/material.dart';

/// A form section as `FormGroup` draws it: a header line, then a white card
/// of [rows] rows, each a short label in the label column and a value.
/// [header] false leaves the header out, as for a field on its own.
class SkeletonFormGroup extends StatelessWidget {
  const SkeletonFormGroup({super.key, this.rows = 3, this.header = true});

  final int rows;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (header)
          const Padding(
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: SkeletonLine(widthFactor: 0.3, height: 16),
          ),
        SkeletonSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < rows; i++) ...<Widget>[
                if (i > 0)
                  const Divider(
                    height: AppSizes.divider,
                    indent: AppSpacing.lg,
                  ),
                SizedBox(
                  height: AppSizes.button,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      children: <Widget>[
                        const SizedBox(
                          width: AppSizes.formLabel,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: SkeletonBox(width: 72, height: 16),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SkeletonBox(width: i.isEven ? 104 : 72, height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
