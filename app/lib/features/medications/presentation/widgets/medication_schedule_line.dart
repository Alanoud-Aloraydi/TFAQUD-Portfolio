import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/widgets/display/weekday_strip.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
