import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:app/core/widgets/loading/skeleton_details_card.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/circles/presentation/widgets/contact_skeleton.dart';
import 'package:flutter/material.dart';

/// The medical file while it loads: the card of six details, the contacts
/// title, two contacts, and the add button.
class MedicalFileSkeleton extends StatelessWidget {
  const MedicalFileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonDetailsCard(rows: 6),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.4, height: 20),
        SizedBox(height: AppSpacing.md),
        ContactSkeleton(),
        SizedBox(height: AppSpacing.md),
        ContactSkeleton(),
        SizedBox(height: AppSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SkeletonBox(
            width: 140,
            height: AppSizes.touch,
            radius: AppRadius.capsule,
          ),
        ),
      ],
    );
  }
}
