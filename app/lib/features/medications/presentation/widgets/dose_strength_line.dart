import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «ميتفورمين 500 ملغ»: a medicine's name with its strength beside it, the
/// same in a plan card and a record card.
class DoseStrengthLine extends StatelessWidget {
  const DoseStrengthLine({
    super.key,
    required this.name,
    required this.strengthValue,
    required this.strengthUnit,
  });

  final String name;
  final double strengthValue;
  final StrengthUnit strengthUnit;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: <Widget>[
        Text(name, style: text.titleMedium),
        Text(
          '${formatMedicationNumber(strengthValue)} '
          '${context.tr('medications.strength_display.${strengthUnit.name}')}',
          style: text.labelSmall,
        ),
      ],
    );
  }
}
