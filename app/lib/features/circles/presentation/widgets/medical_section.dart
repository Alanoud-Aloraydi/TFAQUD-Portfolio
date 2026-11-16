import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:flutter/material.dart';

/// One question of the medical file: its heading, and the answers in the
/// same white card as every other section, so none looks heavier than the
/// one above it.
class MedicalSection extends StatelessWidget {
  const MedicalSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SizedBox(height: AppSpacing.xl),
      InsetText.header(title),
      const SizedBox(height: AppSpacing.sm),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppSurfaces.card(),
        child: child,
      ),
    ],
  );
}
