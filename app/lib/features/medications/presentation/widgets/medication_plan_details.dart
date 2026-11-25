import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/core/widgets/display/weekday_strip.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/dose_text.dart';
import 'package:app/features/medications/presentation/widgets/medication_strength_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What a medicine's plan card opens, in groups: «الجدول» (each time in
/// bold with its dose and days), «عن الدواء» (the reason, the instructions,
/// when a dose counts as missed), «الأشخاص» (who added and last changed it,
/// with their pictures), and, for a member who manages medicines, «إيقاف
/// الدواء» in red while the plan runs or is still to come.
List<Widget> medicationPlanDetails(
  BuildContext context, {
  required String circleId,
  required MedicationPlan plan,
  required bool canManage,
  required DateTime today,
}) {
  final PlanStatus status = plan.statusOn(today);
  final bool stoppable =
      canManage &&
      (status == PlanStatus.active || status == PlanStatus.scheduled);
  return <Widget>[
    PlanFactGroup(
      title: context.tr('plan_details.schedule'),
      children: <Widget>[
        for (final schedule in plan.version.schedules)
          MedicationScheduleLine(schedule: schedule),
        if (plan.version.schedules.isEmpty)
          PlanFact(
            icon: CareIcons.pill,
            value: context.tr('medications.no_schedules_line'),
          ),
      ],
    ),
    medicationAboutGroup(context, plan.version),
    if (plan.createdByName != null || plan.lastEditedByName != null)
      medicationPeopleGroup(context, circleId: circleId, plan: plan),
    if (stoppable)
      StopButton(
        label: context.tr('medications.discontinue'),
        onPressed: () => discontinueMedication(context, plan),
      ),
  ];
}

/// «الأشخاص»: who added the medicine and who changed it last, with their
/// pictures. The last editor is left out while it is the person who added
/// it, so one name is not read twice.
Widget medicationPeopleGroup(
  BuildContext context, {
  required String circleId,
  required MedicationPlan plan,
}) {
  return PlanFactGroup(
    title: context.tr('plan_details.people'),
    children: <Widget>[
      if (plan.createdByName case final String name)
        PlanPersonFact(
          label: context.tr('medications.added_by'),
          name: name,
          circleId: circleId,
          accountId: plan.createdByAccountId,
          avatarCode: plan.createdByAvatarCode,
        ),
      if (plan.lastEditedByName case final String name
          when name != plan.createdByName)
        PlanPersonFact(
          label: context.tr('medications.last_edited_by'),
          name: name,
          circleId: circleId,
          accountId: plan.lastEditedByAccountId,
          avatarCode: plan.lastEditedByAvatarCode,
        ),
    ],
  );
}

/// Which plans «السجل» shows: every one, the ones still running, or the
/// ones already behind.
enum MedicationRecordFilter {
  all,
  current,
  previous;

  /// Whether [plan] belongs in the list on [today].
  bool keeps(MedicationPlan plan, DateTime today) => switch (this) {
    all => true,
    current => !plan.isPreviousOn(today),
    MedicationRecordFilter.previous => plan.isPreviousOn(today),
  };

  /// The key of its words, under `medications.filter`.
  String get labelKey => 'medications.filter.$name';
}

/// One schedule of a medicine in its opened details: the time in bold, the
/// dose as a badge at the end, and the days it repeats on under the time.
class MedicationScheduleLine extends StatelessWidget {
  const MedicationScheduleLine({super.key, required this.schedule});

  final MedicationSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final TextStyle? small = Theme.of(context).textTheme.labelMedium;
    return PlanFact(
      icon: ScheduleIcons.clock,
      value: clockText(schedule.time),
      trailing: StatusBadge(
        text: formatMedicationDose(
          context,
          schedule.doseValue,
          schedule.doseUnit,
        ),
        tone: StatusTone.neutral,
        icon: CareIcons.pill,
      ),
      below: switch (schedule.repeat) {
        ScheduleRepeat.monthly => Text(
          formatMonthDays(context, schedule.monthDays),
          style: small,
        ),
        ScheduleRepeat.interval => Text(
          formatInterval(context, schedule.intervalDays ?? 1),
          style: small,
        ),
        ScheduleRepeat.weekly => WeekdayStrip(days: schedule.weekdays),
      },
    );
  }
}

/// Asks to confirm, then stops [plan] and says how it went; true once it
/// is stopped. [context] must stay mounted while the answer is awaited.
Future<bool> discontinueMedication(
  BuildContext context,
  MedicationPlan plan,
) async {
  final bool? confirmed = await showAppAlert<bool>(
    context,
    title: context.tr('medications.discontinue_title'),
    message: context.tr('medications.discontinue_message'),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('medications.discontinue_confirm'),
        value: true,
        destructive: true,
      ),
    ],
  );
  if (confirmed != true || !context.mounted) return false;
  final MedicationsCubit cubit = context.read<MedicationsCubit>();
  final bool changed = await cubit.discontinue(plan);
  if (!context.mounted) return changed;
  if (changed) {
    AppToast.show(context, 'toast.medication_stopped');
    return true;
  }
  final String? message = cubit.state.messageKey;
  if (message != null) AppToast.show(context, message, kind: ToastKind.error);
  return false;
}
