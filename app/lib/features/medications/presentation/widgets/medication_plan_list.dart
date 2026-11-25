import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/scroll_insets.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/layout/plan_fact_group.dart';
import 'package:app/core/widgets/layout/record_item_card.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/layout/section_title.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_number.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Displays the medication plan list UI.
class MedicationPlanList extends StatelessWidget {
  const MedicationPlanList({
    super.key,
    this.title,
    required this.emptyText,
    required this.plans,
    required this.circleId,
    required this.canManage,
    this.shrinkWrap = false,
    this.header,
    this.onAdd,
  });

  /// The section title. Null when something above already names the list,
  /// such as the record tab's filter.
  final String? title;
  final String emptyText;
  final List<MedicationPlan> plans;
  final String circleId;
  final bool canManage;
  final bool shrinkWrap;

  /// Shown above the title, such as the tab's large title.
  final Widget? header;

  /// Opens the new-plan flow; null (or [canManage] false) hides the action.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ?header,
      if (title != null) ...[
        SectionHeader(title!),
        const SizedBox(height: AppSpacing.md),
      ],
      if (plans.isEmpty)
        EmptyStateNote.section(
          emptyText,
          actionLabel: canManage ? context.tr('add.medication') : null,
          onAction: canManage ? onAdd : null,
        )
      else
        for (final plan in plans) ...[
          MedicationPlanCard(
            circleId: circleId,
            plan: plan,
            canManage: canManage,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
    ];
    if (shrinkWrap) return Column(children: children);
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: children,
    );
  }
}

/// The medicines «السجل» keeps under its filter, or the note that this
/// filter has none, with «جدولة دواء» when [canAdd].
List<Widget> medicationRecordList(
  BuildContext context, {
  required String circleId,
  required List<MedicationPlan> plans,
  bool canAdd = false,
}) {
  if (plans.isEmpty) {
    return <Widget>[
      EmptyStateNote.section(
        context.tr('medications.no_records'),
        actionLabel: canAdd ? context.tr('add.medication') : null,
        onAction: canAdd
            ? () => context.push(CareItemRoutes.newMedication(circleId))
            : null,
      ),
    ];
  }
  return <Widget>[
    for (final plan in plans) ...<Widget>[
      MedicationRecordCard(circleId: circleId, plan: plan),
      const SizedBox(height: AppItemCard.listGap),
    ],
  ];
}

/// A medicine in «السجل»: its plan status and start, a revision waiting, the
/// last explicit dose, and a tap that opens its full record.
class MedicationRecordCard extends StatelessWidget {
  const MedicationRecordCard({
    super.key,
    required this.circleId,
    required this.plan,
  });

  final String circleId;
  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final version = plan.version;
    final today = PatientClockScope.of(context).today();
    return RecordItemCard(
      leading: MedicationLeading(circleId: circleId, planId: plan.id),
      title: DoseStrengthLine(
        name: version.name,
        strengthValue: version.strengthValue,
        strengthUnit: version.strengthUnit,
      ),
      subtitle: Text(
        formatStartDate(context, version.startsOn, today: today),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      status: PlanStatusBadge(plan.statusOn(today)),
      onTap: () => context.push(
        CareItemRoutes.medicationDetails(circleId, plan.id),
        extra: false,
      ),
      body: medicationRecordBody(context, circleId: circleId, plan: plan),
    );
  }
}

/// What a medicine's record card holds under its title: the day it was last
/// revised (only for a plan that was), the last explicit dose, and the line
/// that says the card opens the full record.
List<Widget> medicationRecordBody(
  BuildContext context, {
  required String circleId,
  required MedicationPlan plan,
}) {
  final TextTheme text = Theme.of(context).textTheme;
  return <Widget>[
    if (plan.history.length > 1)
      PlanInfoBox(
        child: Text(
          context.tr(
            'medications.revised_on',
            args: <String>[
              formatMedicationDate(context, plan.history.last.effectiveFromOn),
            ],
          ),
          style: text.bodySmall,
        ),
      ),
    MedicationLastDoseBox(circleId: circleId, last: plan.lastRecord),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(context.tr('medications.full_record'), style: text.labelMedium),
        const Icon(ArrowIcons.forward, size: AppSizes.iconSmall),
      ],
    ),
  ];
}

/// «آخر جرعة»: when the last explicit dose of a medicine was taken or
/// skipped, by whom, and why it was skipped; or that none was recorded.
class MedicationLastDoseBox extends StatelessWidget {
  const MedicationLastDoseBox({
    super.key,
    required this.circleId,
    required this.last,
  });

  final String circleId;
  final MedicationLastRecord? last;

  @override
  Widget build(BuildContext context) {
    final TextStyle? small = Theme.of(context).textTheme.bodySmall;
    final MedicationLastRecord? last = this.last;
    return PlanInfoBox(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              medicationLastDoseText(context, circleId: circleId, last: last),
              style: small,
            ),
            if (last?.recordedByName case final String name)
              RecorderLine(
                name: name,
                photoPath: personPhotoPath(circleId, last!.recordedByAccountId),
                avatarCode: last.recordedByAvatarCode,
              ),
            if (last?.outcome == DoseOutcome.skipped &&
                last?.skipReasonCode != null)
              Text(
                context.tr(
                  'medications.skip_reason_line',
                  args: <String>[
                    doseSkipReasonLabel(
                      context,
                      last!.skipReasonCode,
                      last.skipReasonNote,
                    ),
                  ],
                ),
                style: small,
              ),
          ],
        ),
      ),
    );
  }
}

/// The sentence of «آخر جرعة». The day and the time are the patient's own:
/// a dose recorded with a moment is read on their clock, and one without
/// keeps the time it was scheduled for.
String medicationLastDoseText(
  BuildContext context, {
  required String circleId,
  required MedicationLastRecord? last,
}) {
  if (last == null) return context.tr('medications.no_recorded_dose');
  final DateTime? taken = last.takenAt == null
      ? null
      : PatientClockScope.of(context).wallTime(last.takenAt!);
  return CareVoice.tr(
    context,
    circleId,
    last.outcome == DoseOutcome.taken
        ? 'medications.last_taken_record'
        : 'medications.last_skipped_record',
    args: <String>[
      formatMedicationDate(context, taken ?? last.scheduledOn),
      taken == null ? clockText(last.time) : wallTimeText(taken),
    ],
  );
}
