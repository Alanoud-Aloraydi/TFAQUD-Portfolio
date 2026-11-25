import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_border.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_circle.dart';
import 'package:flutter/material.dart';
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

/// The start of a dose row: the medicine's photo when it has one, otherwise
/// the shared medicine icon. Both are the same size, so the rows line up.
class DoseRowLeading extends StatelessWidget {
  const DoseRowLeading({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) {
    const Widget icon = TodayTaskKindIcon(
      icon: CareVisuals.medicationIcon,
      background: CareVisuals.medicationTile,
    );
    return MedicationPhotoBuilder(
      circleId: circleId,
      planId: planId,
      builder: (BuildContext context, bytes) => bytes == null
          ? icon
          : MedicationPhotoImage(
              bytes: bytes,
              width: AppItemCard.leading,
              height: AppItemCard.leading,
            ),
    );
  }
}
