import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:flutter/material.dart';

// Each medicine page has its own skeleton (design system Skeleton), drawn in
// the shape of the page it stands for, so nothing jumps when the content
// comes.

/// «اليوم» while it loads: the large title and the date, «أدوية اليوم», then
/// dose rows as the real ones: the time on the start side, the medicine's
/// lines, and the record buttons, divided by lines.
class TodaySkeleton extends StatelessWidget {
  const TodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      children: <Widget>[
        SkeletonLargeTitle(width: 96, subtitle: true),
        SkeletonLine(widthFactor: 0.32, height: 24),
        SizedBox(height: AppSpacing.md),
        DoseRowSkeleton(withButtons: true),
        Divider(height: AppSizes.divider),
        DoseRowSkeleton(),
        Divider(height: AppSizes.divider),
        DoseRowSkeleton(),
      ],
    );
  }
}

/// One dose row: the time column with its line, the medicine's name,
/// strength and dose, and (when [withButtons]) the record buttons.
class DoseRowSkeleton extends StatelessWidget {
  const DoseRowSkeleton({super.key, this.withButtons = false});

  final bool withButtons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: <Widget>[
                    SkeletonBox(width: 52, height: 16),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(width: 44, height: 12),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SkeletonLine(widthFactor: 0.55, height: 20),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonLine(widthFactor: 0.3),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonLine(widthFactor: 0.4, height: 12),
                  ],
                ),
              ),
            ],
          ),
          if (withButtons) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const SkeletonBox(
              height: AppSizes.button,
              radius: AppRadius.capsule,
            ),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(
              height: AppSizes.touch,
              radius: AppRadius.capsule,
            ),
          ],
        ],
      ),
    );
  }
}

/// «الخطة» while it loads ([filter] false) and «السجل» ([filter] true): the
/// large title, the segmented control on «السجل» or the section title on
/// «الخطة», then medicine cards.
class PlansSkeleton extends StatelessWidget {
  const PlansSkeleton({super.key, this.filter = false});

  final bool filter;

  @override
  Widget build(BuildContext context) {
    return SkeletonPage(
      children: <Widget>[
        const SkeletonLargeTitle(width: 88),
        if (filter) ...<Widget>[
          const SkeletonBox(height: AppSizes.touch, radius: AppRadius.capsule),
          const SizedBox(height: AppSpacing.xl),
        ] else ...<Widget>[
          const SkeletonLine(widthFactor: 0.38, height: 24),
          const SizedBox(height: AppSpacing.md),
        ],
        for (int i = 0; i < 3; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          const PlanCardSkeleton(),
        ],
      ],
    );
  }
}

/// A medicine card: the icon, the name, the status pill and the chevron,
/// the strength line, and the two lines with an icon each.
class PlanCardSkeleton extends StatelessWidget {
  const PlanCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SkeletonBox(width: 24, height: 24, radius: AppRadius.xs),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonLine(widthFactor: 0.55, height: 20)),
              SkeletonBox(width: 56, height: 24, radius: AppRadius.s),
              SizedBox(width: AppSpacing.sm),
              SkeletonBox(width: 12, height: 20),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          SkeletonLine(widthFactor: 0.35),
          SizedBox(height: AppSpacing.md),
          _IconLine(widthFactor: 0.45),
          SizedBox(height: AppSpacing.xs),
          _IconLine(widthFactor: 0.6),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SkeletonBox(width: 16, height: 16, radius: AppRadius.xs),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: SkeletonLine(widthFactor: widthFactor, height: 12)),
      ],
    );
  }
}

/// A medicine's page while it loads: the name and strength, the details
/// card, and the dose times.
class MedicationDetailsSkeleton extends StatelessWidget {
  const MedicationDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      children: <Widget>[
        SkeletonLine(widthFactor: 0.55, height: 24),
        SizedBox(height: AppSpacing.sm),
        SkeletonLine(widthFactor: 0.3),
        SizedBox(height: AppSpacing.lg),
        SkeletonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LabelValue(valueWidth: 0.5),
              SizedBox(height: AppSpacing.md),
              _LabelValue(valueWidth: 0.4),
              SizedBox(height: AppSpacing.md),
              _LabelValue(valueWidth: 0.6),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.3, height: 20),
        SizedBox(height: AppSpacing.md),
        _LabelValue(valueWidth: 0.45),
        SizedBox(height: AppSpacing.md),
        _LabelValue(valueWidth: 0.45),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.valueWidth});

  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SkeletonLine(widthFactor: 0.25, height: 12),
        const SizedBox(height: AppSpacing.sm),
        SkeletonLine(widthFactor: valueWidth, height: 16),
      ],
    );
  }
}

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

/// The dose history inside a medicine's page while it loads: its title and
/// dose rows. It sits inside the page's scrolling list, so it does not
/// scroll itself.
class DoseHistorySkeleton extends StatelessWidget {
  const DoseHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBlock(
      children: <Widget>[
        SkeletonLine(widthFactor: 0.35, height: 24),
        SizedBox(height: AppSpacing.sm),
        DoseRowSkeleton(),
        Divider(height: AppSizes.divider),
        DoseRowSkeleton(),
      ],
    );
  }
}
