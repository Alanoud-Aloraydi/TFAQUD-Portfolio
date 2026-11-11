import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_leading.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A dose in «اليوم»: a [CareItemRow] whose tap opens the medicine.
class TodayDoseRow extends StatelessWidget {
  const TodayDoseRow({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
    required this.now,
    this.showThumbnail = false,
  });

  final DoseOccurrence occurrence;
  final String circleId;

  /// Passed on to the medicine's page.
  final bool canManage;
  final DateTime now;
  final bool showThumbnail;

  @override
  Widget build(BuildContext context) {
    final DoseRowStatus status = DoseRowStatus.of(context, occurrence, now);
    final DoseRecord? record = occurrence.record;
    final String dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    final bool canRecord = canRecordOccurrence(
      resolved: record != null,
      scheduledAt: wallClockAt(occurrence.scheduledOn, occurrence.time),
      now: now,
    );
    return CareItemRow(
      time: clockText(occurrence.time),
      tone: status.unrecorded ? TodayRowTone.attention : TodayRowTone.normal,
      leading: DoseRowLeading(
        circleId: circleId,
        planId: occurrence.planId,
        showPhoto: showThumbnail,
      ),
      title: '${occurrence.name} ${doseStrengthText(context, occurrence)}',
      subtitle: occurrence.instructions == null
          ? dose
          : '$dose · ${occurrence.instructions}',
      details: <Widget>[
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
      ],
      status: TodayTaskStatusBadge(text: status.label, tone: status.tone),
      onTap: () => context.push(
        Routes.medicationDetails(circleId, occurrence.planId),
        extra: canManage,
      ),
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
