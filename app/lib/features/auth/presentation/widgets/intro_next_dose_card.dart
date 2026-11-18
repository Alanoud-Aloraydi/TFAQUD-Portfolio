import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/features/auth/presentation/widgets/intro_next_dose_bar.dart';
import 'package:app/features/auth/presentation/widgets/intro_next_dose_header.dart';
import 'package:app/features/auth/presentation/widgets/intro_next_dose_medicine.dart';
import 'package:flutter/material.dart';

/// The dark card of the next dose: the medicine, its time, and a bar of the
/// time left.
class IntroNextDoseCard extends StatelessWidget {
  const IntroNextDoseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ShapeDecoration(
        color: AppSemanticColors.textPrimary,
        shape: AppRadius.shape(AppRadius.l),
        shadows: AppSurfaces.floatShadow,
      ),
      child: const MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            IntroNextDoseHeader(),
            SizedBox(height: AppSpacing.md),
            IntroNextDoseMedicine(),
            SizedBox(height: AppSpacing.md),
            IntroNextDoseBar(),
          ],
        ),
      ),
    );
  }
}
