import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_form_group.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:flutter/material.dart';

/// The medicine form while the medicine loads for editing: its three
/// grouped sections, as `FormGroup` draws them.
class MedicationFormSkeleton extends StatelessWidget {
  const MedicationFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      children: <Widget>[
        SkeletonFormGroup(rows: 5),
        SizedBox(height: AppSpacing.xl),
        SkeletonFormGroup(rows: 2),
        SizedBox(height: AppSpacing.xl),
        SkeletonFormGroup(rows: 4),
      ],
    );
  }
}
