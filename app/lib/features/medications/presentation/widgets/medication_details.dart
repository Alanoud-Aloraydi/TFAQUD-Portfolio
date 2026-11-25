import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/localization/weekdays_text.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/fact_pill.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/widgets/dose_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The details of a medicine, laid out like the medical file: the name and
/// the strength as the title, then the facts in a white card, then the dose
/// times in a grouped card under a small header. The cards reach the edges
/// and the text inside them starts 16 in.
class MedicationDetails extends StatelessWidget {
  const MedicationDetails({super.key, required this.plan});

  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final version = plan.version;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(version.name, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            '${formatMedicationNumber(version.strengthValue)} '
            '${context.tr('medications.strength_display.${version.strengthUnit.name}')}',
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsCard(children: medicationFactRows(context, plan)),
          const SizedBox(height: AppSpacing.xl),
          InsetGroup(
            header: context.tr('medications.dose_schedules'),
            footer: version.schedules.isEmpty
                ? context.tr('medications.no_schedules_line')
                : null,
            children: [
              for (final schedule in version.schedules)
                MedicationScheduleRow(schedule: schedule),
            ],
          ),
        ],
      ),
    );
  }
}

/// The facts of a medicine, in the order the page reads them: its form, why
/// it is taken, how, when a dose counts as missed, the treatment period,
/// and, for a plan that has not started, the day it takes over.
List<Widget> medicationFactRows(BuildContext context, MedicationPlan plan) {
  final MedicationVersion version = plan.version;
  final DateTime today = PatientClockScope.of(context).today();
  Widget row(String label, String value) =>
      InfoRow(label: context.tr(label), value: value);
  return <Widget>[
    row(
      'medications.dosage_form',
      context.tr('medications.form.${version.dosageForm.name}'),
    ),
    if (version.reason case final value?) row('medications.reason', value),
    if (version.instructions case final value?)
      row('medications.instructions', value),
    row(
      'medications.missed_after',
      arabicCount(context, ArabicCount.minutes, version.missedAfterMinutes),
    ),
    row(
      'medications.treatment_period',
      formatMedicationPeriod(
        context,
        version.startsOn,
        version.endsOn,
        today: today,
      ),
    ),
    if (plan.isScheduledOn(today))
      row(
        'medications.effective_from',
        formatMedicationDate(context, version.effectiveFromOn),
      ),
  ];
}

/// One dose time in the card, in soft pills on one line: «8:00 ص»،
/// «1 حبة»، «كل يومين»; the note written for it under them.
class MedicationScheduleRow extends StatelessWidget {
  const MedicationScheduleRow({super.key, required this.schedule});

  final MedicationSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final String? note = schedule.instructions;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inset,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final String fact in <String>[
                  clockText(schedule.time),
                  formatMedicationDose(
                    context,
                    schedule.doseValue,
                    schedule.doseUnit,
                  ),
                  scheduleDaysText(context, schedule),
                ])
                  if (fact.isNotEmpty) FactPill(fact),
              ],
            ),
            if (note != null && note.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                note,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.tokens.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Which days a schedule repeats on, in its own way of repeating: the days
/// of the month, every so many days, or the days of the week.
String scheduleDaysText(BuildContext context, MedicationSchedule schedule) =>
    switch (schedule.repeat) {
      ScheduleRepeat.monthly => formatMonthDays(context, schedule.monthDays),
      ScheduleRepeat.interval => formatInterval(
        context,
        schedule.intervalDays ?? 1,
      ),
      ScheduleRepeat.weekly => formatWeekdays(context, schedule.weekdays),
    };
