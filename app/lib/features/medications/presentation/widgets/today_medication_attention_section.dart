// Each medicine page has its own skeleton (design system Skeleton), drawn in
// the shape of the page it stands for, so nothing jumps when the content
// comes.
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/feedback/tap_focus_listener.dart';
import 'package:app/core/widgets/loading/skeleton_form_group.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/attention_dose_cards.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The one «يحتاج انتباهك» box of «اليوم»: the doses that need attention,
/// then [extra] (measurements and visits), under one title counting both.
/// Folded, it opens for a tapped notification about one of [focusKeys].
class TodayMedicationAttentionSection extends StatefulWidget {
  const TodayMedicationAttentionSection({
    super.key,
    required this.occurrences,
    required this.circleId,
    required this.canManage,
    this.extra,
    this.extraCount = 0,
    this.focusKeys = const <String>{},
  });
  final List<DoseOccurrence> occurrences;
  final String circleId;
  final bool canManage;

  /// More cards after the doses, and how many they are.
  final Widget? extra;
  final int extraCount;
  final Set<String> focusKeys;

  @override
  State<TodayMedicationAttentionSection> createState() => _SectionState();
}

class _SectionState extends State<TodayMedicationAttentionSection> {
  bool _expanded = true;

  void _openFor(String key) {
    if (_expanded || !widget.focusKeys.contains(key)) return;
    setState(() => _expanded = true);
  }

  @override
  Widget build(BuildContext context) => TapFocusListener(
    onWaiting: _openFor,
    child: AttentionBox(
      title: context.tr('today_dashboard.attention'),
      count: widget.occurrences.length + widget.extraCount,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      child: Column(
        children: <Widget>[
          AttentionDoseCards(
            occurrences: widget.occurrences,
            circleId: widget.circleId,
            canManage: widget.canManage,
          ),
          if (widget.extra case final Widget extra) ...<Widget>[
            if (widget.occurrences.isNotEmpty)
              const SizedBox(height: AppSpacing.sm),
            extra,
          ],
        ],
      ),
    ),
  );
}

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
