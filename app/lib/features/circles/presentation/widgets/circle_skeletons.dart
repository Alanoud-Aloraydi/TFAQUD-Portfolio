import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';

// Each circle page has its own skeleton (design system Skeleton), drawn in
// the shape of the page it stands for. These pages already have their
// header and side padding around the body, so the skeletons add neither.

/// The notifications while they load: the section title, then request
/// cards with the round avatar, the name, two lines, the pill, and the two
/// reply buttons side by side.
class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonLine(widthFactor: 0.4, height: 16),
        SizedBox(height: AppSpacing.md),
        _RequestCardSkeleton(),
        SizedBox(height: AppSpacing.md),
        _RequestCardSkeleton(),
      ],
    );
  }
}

class _RequestCardSkeleton extends StatelessWidget {
  const _RequestCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonSurface(
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonCircle(size: 40),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SkeletonLine(widthFactor: 0.5, height: 16),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonLine(widthFactor: 0.9, height: 12),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonLine(widthFactor: 0.65, height: 12),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              SkeletonBox(width: 64, height: 24, radius: AppRadius.s),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: SkeletonBox(
                  height: AppSizes.touch,
                  radius: AppRadius.capsule,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SkeletonBox(
                  height: AppSizes.touch,
                  radius: AppRadius.capsule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
        SkeletonLine(widthFactor: 0.4, height: 18),
        SizedBox(height: AppSpacing.md),
        _ContactSkeleton(),
        SizedBox(height: AppSpacing.md),
        _ContactSkeleton(),
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

class _ContactSkeleton extends StatelessWidget {
  const _ContactSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonSurface(
      child: Row(
        children: <Widget>[
          SkeletonCircle(size: 40),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonLine(widthFactor: 0.45, height: 16),
                SizedBox(height: AppSpacing.sm),
                SkeletonLine(widthFactor: 0.35, height: 12),
              ],
            ),
          ),
          SkeletonBox(width: 20, height: 20, radius: AppRadius.xs),
        ],
      ),
    );
  }
}

/// The emergency card while it loads: the dark name card (drawn as one
/// shape, since its real color is ink) and the details card with its
/// sections.
class EmergencyCardSkeleton extends StatelessWidget {
  const EmergencyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonBox(height: 132, radius: AppRadius.l),
        SizedBox(height: AppSpacing.lg),
        SkeletonSurface(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: <Widget>[
              _SectionSkeleton(valueWidth: 0.3),
              Divider(height: 1),
              _SectionSkeleton(valueWidth: 0.7),
              Divider(height: 1),
              _SectionSkeleton(valueWidth: 0.55, lines: 2),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({required this.valueWidth, this.lines = 1});

  final double valueWidth;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SkeletonLine(widthFactor: 0.3, height: 12),
          for (int i = 0; i < lines; i++) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            SkeletonLine(widthFactor: valueWidth, height: 16),
          ],
        ],
      ),
    );
  }
}

/// The medical file's edit page while it loads: the name fields and the
/// pickers as form rows, then the choices as rows of chips.
class MedicalFileEditSkeleton extends StatelessWidget {
  const MedicalFileEditSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonFormGroup(rows: 1, header: false),
        SizedBox(height: AppSpacing.md),
        SkeletonFormGroup(rows: 1, header: false),
        SizedBox(height: AppSpacing.md),
        SkeletonFormGroup(rows: 1, header: false),
        SizedBox(height: AppSpacing.md),
        SkeletonFormGroup(rows: 1, header: false),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.3, height: 14),
        SizedBox(height: AppSpacing.sm),
        _ChipsSkeleton(widths: <double>[56, 56, 56, 56, 64, 64]),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.35, height: 14),
        SizedBox(height: AppSpacing.sm),
        _ChipsSkeleton(widths: <double>[96, 72, 112, 88, 64]),
      ],
    );
  }
}

class _ChipsSkeleton extends StatelessWidget {
  const _ChipsSkeleton({required this.widths});

  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final double width in widths)
          SkeletonBox(width: width, height: 36, radius: AppRadius.capsule),
      ],
    );
  }
}
