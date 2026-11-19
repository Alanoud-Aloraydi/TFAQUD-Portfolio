import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_controls_layout.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_details.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_leading.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_texts.dart';
import 'package:app/features/medications/presentation/widgets/navigate_to_medication.dart';
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
