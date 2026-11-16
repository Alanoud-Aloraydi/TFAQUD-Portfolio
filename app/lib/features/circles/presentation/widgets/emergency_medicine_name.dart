import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:flutter/material.dart';

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
