// Each medicine page has its own skeleton (design system Skeleton), drawn in
// the shape of the page it stands for, so nothing jumps when the content
// comes.

import 'package:app/app/services/reminders/reminder_payloads.dart';
import 'package:app/core/constants/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/core/widgets/feedback/tap_focus_listener.dart';
import 'package:app/core/widgets/loading/skeleton_form_group.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/attention_dose_text.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_outcome.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_skeleton.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_circle.dart';
import 'package:app/features/medications/presentation/widgets/navigate_to_medication.dart';
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

/// The doses of «يحتاج انتباهك», a gap between each. The one a tapped
/// notification is about is brought into view and tinted ([FocusMark]).
class AttentionDoseCards extends StatelessWidget {
  const AttentionDoseCards({
    super.key,
    required this.occurrences,
    required this.circleId,
    required this.canManage,
  });

  final List<DoseOccurrence> occurrences;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      for (final DoseOccurrence item in occurrences) ...<Widget>[
        FocusMark(
          itemKey: doseSnoozeKey(circleId, item),
          radius: AppRadius.field,
          child: AttentionMedicationCard(
            occurrence: item,
            circleId: circleId,
            canManage: canManage,
          ),
        ),
        if (item != occurrences.last) const SizedBox(height: AppSpacing.sm),
      ],
    ],
  );
}

/// A dose of «يحتاج انتباهك»: what it was and when, over the buttons that
/// record it late.
class AttentionMedicationCard extends StatelessWidget {
  const AttentionMedicationCard({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AttentionMedicationLines(
            occurrence: occurrence,
            circleId: circleId,
            canManage: canManage,
          ),
          const SizedBox(height: AppSpacing.sm),
          DoseRecordControls(
            occurrence: occurrence,
            layout: DoseControlsLayout.attention,
            circleId: circleId,
          ),
        ],
      ),
    );
  }
}

/// A late dose of «يحتاج انتباهك»: the pill, then the three lines, read in
/// one breath and opening with the medicine, and tapped to open it.
class AttentionMedicationLines extends StatelessWidget {
  const AttentionMedicationLines({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final String dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    final String title =
        '${occurrence.name} ${doseStrengthText(context, occurrence)}';
    final String when =
        '${formatMedicationDate(context, occurrence.scheduledOn)}'
        '، ${clockText(occurrence.time)}';
    final String how = occurrence.instructions == null
        ? dose
        : '$dose، ${occurrence.instructions}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AttentionDosePill(circleId: circleId, planId: occurrence.planId),
        const SizedBox(width: AppSpacing.tight),
        Expanded(
          child: MergeSemantics(
            child: Semantics(
              button: true,
              label: spoken('$title، $when، $how'),
              child: InkWell(
                onTap: () =>
                    openMedication(context, circleId, occurrence, canManage),
                child: ExcludeSemantics(
                  child: AttentionDoseText(title: title, when: when, how: how),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The medicine's photo beside a late dose, or a pill while it has none. It
/// is decoration; the name says what it is.
class AttentionDosePill extends StatelessWidget {
  const AttentionDosePill({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: MedicationPhotoCircle(
        circleId: circleId,
        planId: planId,
        size: 34,
        fallback: CircleAvatar(
          radius: 17,
          backgroundColor: context.tokens.error.withValues(alpha: .08),
          child: Icon(
            TafaqodPhosphorIcons.pill,
            color: context.tokens.error,
            size: 18,
          ),
        ),
      ),
    );
  }
}
