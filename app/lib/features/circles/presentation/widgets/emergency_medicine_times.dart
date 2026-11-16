import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter/material.dart';

/// A medicine's dose times, one under the other: «8:00 ص، 1 قرص», where
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
