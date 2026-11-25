import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_outcome.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/dose_text.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_border.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_circle.dart';
import 'package:app/features/medications/presentation/widgets/navigate_to_medication.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A dose in «اليوم»: a [CareItemRow] whose tap opens the medicine.
class TodayDoseRow extends StatelessWidget {
  const TodayDoseRow({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
    required this.now,
  });

  final DoseOccurrence occurrence;
  final String circleId;

  /// Passed on to the medicine's page.
  final bool canManage;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final DoseRowStatus status = DoseRowStatus.of(context, occurrence, now);
    final bool canRecord = canRecordOccurrence(
      resolved: occurrence.record != null,
      scheduledAt: wallClockAt(occurrence.scheduledOn, occurrence.time),
      now: now,
    );
    return CareItemRow(
      time: clockText(occurrence.time),
      spokenLabel: doseRowSpokenLabel(context, occurrence, status),
      tone: status.unrecorded ? TodayRowTone.attention : TodayRowTone.normal,
      leading: DoseRowLeading(circleId: circleId, planId: occurrence.planId),
      title: doseRowTitle(context, occurrence),
      subtitle: doseRowSubtitle(context, occurrence),
      details: doseRowDetails(context, occurrence, circleId, status),
      status: StatusBadge(text: status.label, tone: status.tone),
      onTap: () => openMedication(context, circleId, occurrence, canManage),
      actions: canRecord
          ? DoseRecordControls(
              occurrence: occurrence,
              layout: DoseControlsLayout.attention,
              circleId: circleId,
            )
          : null,
    );
  }
}

/// What a dose row says under its two first lines: how late it was, who
/// recorded it, and the reason a skipped dose was not taken.
List<Widget> doseRowDetails(
  BuildContext context,
  DoseOccurrence occurrence,
  String circleId,
  DoseRowStatus status,
) {
  final DoseRecord? record = occurrence.record;
  return <Widget>[
    if (status.lateBy case final String lateBy)
      Text(lateBy, style: Theme.of(context).textTheme.bodySmall),
    if (record?.recordedByName case final String name)
      RecorderLine(
        name: name,
        photoPath: personPhotoPath(circleId, record!.recordedByAccountId),
        avatarCode: record.recordedByAvatarCode,
      ),
    if (record?.outcome == DoseOutcome.skipped &&
        record?.skipReasonCode != null)
      Text(
        context.tr(
          'medications.skip_reason_line',
          args: <String>[doseSkipReasonText(context, record!)],
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
  ];
}

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
