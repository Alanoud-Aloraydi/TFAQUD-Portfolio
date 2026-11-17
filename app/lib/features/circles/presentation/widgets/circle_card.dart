import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/widgets/circle_card_content.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:flutter/material.dart';

/// The patient card: the circle's name, who it cares for, three facts from
/// the medical file, and the app mode the patient was given. A 2-point slate
/// edge, no shadow. The mode is shown only; it is set when the circle is
/// created. Without a [medicalFile] (it could not be read) the facts are
/// left out.
class CircleCard extends StatelessWidget {
  const CircleCard({
    super.key,
    required this.circle,
    required this.overview,
    required this.medicalFile,
  });

  final CareCircleSummary circle;
  final CircleOverview overview;
  final MedicalFile? medicalFile;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: AppSemanticColors.surfaceContent,
      // No line around it: white on the page's grey is enough, and smooth.
      shape: AppRadius.shape(AppRadius.l),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: circleCardContent(
          context,
          circleId: circle.id,
          circleName: circle.name,
          overview: overview,
          profile: medicalFile?.profile,
        ),
      ),
    ),
  );
}
