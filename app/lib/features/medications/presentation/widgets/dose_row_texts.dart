import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_text.dart';
import 'package:flutter/widgets.dart';

/// The medicine and its strength, «ميتفورمين 500 ملغ».
String doseRowTitle(BuildContext context, DoseOccurrence occurrence) =>
    '${occurrence.name} ${doseStrengthText(context, occurrence)}';

/// How much is taken, and how, «قرص واحد، بعد الأكل».
String doseRowSubtitle(BuildContext context, DoseOccurrence occurrence) {
  final String dose = formatMedicationDose(
    context,
    occurrence.doseValue,
    occurrence.doseUnit,
  );
  return occurrence.instructions == null
      ? dose
      : '$dose، ${occurrence.instructions}';
}

/// The whole row in one sentence. The name first, then the clock: a day of
/// four doses otherwise opens every row with a number.
String doseRowSpokenLabel(
  BuildContext context,
  DoseOccurrence occurrence,
  DoseRowStatus status,
) {
  return <String>[
    doseRowTitle(context, occurrence),
    clockText(occurrence.time),
    formatMedicationDose(context, occurrence.doseValue, occurrence.doseUnit),
    if (occurrence.instructions case final String how) how,
    if (status.lateBy case final String lateBy) lateBy,
    status.label,
  ].join('، ');
}
