import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter/material.dart';

/// A medicine's dose times, one under the other: «8:00 ص • 1 قرص», where
/// the dot keeps the time and the dose apart.
class EmergencyMedicineTimes extends StatelessWidget {
  const EmergencyMedicineTimes({
    super.key,
    required this.plan,
    required this.words,
    required this.small,
  });

  final MedicationPlan plan;
  final EmergencyCardText words;
  final TextStyle? small;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      for (final MedicationSchedule schedule in plan.version.schedules)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              words.clock(schedule.time),
              textDirection: TextDirection.ltr,
              style: small,
            ),
            // Without it «2» and «11:00» read as «211:00».
            Text(' • ', style: small),
            Text(
              '${formatMedicationNumber(schedule.doseValue)} '
              '${words.unit(schedule.doseUnit.name)}',
              style: small,
            ),
          ],
        ),
    ],
  );
}

/// A medicine's name, and under it its strength and its form.
class EmergencyMedicineName extends StatelessWidget {
  const EmergencyMedicineName({
    super.key,
    required this.plan,
    required this.words,
    required this.small,
  });

  final MedicationPlan plan;
  final EmergencyCardText words;
  final TextStyle? small;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(plan.version.name, style: Theme.of(context).textTheme.titleSmall),
      // The strength is its own run, left to right, so «500 mg» never
      // turns into «mg 500».
      Wrap(
        spacing: AppSpacing.xs,
        children: <Widget>[
          Text(
            '${formatMedicationNumber(plan.version.strengthValue)} '
            '${plan.version.strengthUnit.apiValue}',
            textDirection: TextDirection.ltr,
            style: small,
          ),
          Text(words.form(plan.version.dosageForm.name), style: small),
        ],
      ),
    ],
  );
}
