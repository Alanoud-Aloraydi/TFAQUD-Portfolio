import 'package:app/core/constants/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_outcome.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/dose_text.dart';
import 'package:app/features/medications/presentation/widgets/navigate_to_medication.dart';
import 'package:flutter/material.dart';

/// The next dose of «اليوم»: its time, large, beside the medicine and how
/// much to take.
class NextDoseInfo extends StatelessWidget {
  const NextDoseInfo({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NextDoseClock(time: occurrence.time),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: NextDoseLines(
            occurrence: occurrence,
            circleId: circleId,
            canManage: canManage,
          ),
        ),
      ],
    );
  }
}

/// A dose's time, large: the hour and minutes on one line and «ص» or «م»
/// under them, so the number itself reads from across the room.
class NextDoseClock extends StatelessWidget {
  const NextDoseClock({super.key, required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<String> parts = clockText(time).split(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(parts.first, style: text.displaySmall),
        if (parts.length > 1) Text(parts.last, style: text.labelMedium),
      ],
    );
  }
}

/// The buttons that answer the dose of «اليوم», and nothing at all until it
/// can be recorded — an hour before its time at the earliest.
class TodayDoseAnswer extends StatelessWidget {
  const TodayDoseAnswer({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.now,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final bool canRecord = canRecordOccurrence(
      resolved: occurrence.record != null,
      scheduledAt: wallClockAt(occurrence.scheduledOn, occurrence.time),
      now: now,
    );
    if (!canRecord) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: DoseRecordControls(
        occurrence: occurrence,
        layout: DoseControlsLayout.today,
        circleId: circleId,
      ),
    );
  }
}

/// The medicine of the next dose, tapped to open it, and the dose with its
/// note under the name.
class NextDoseLines extends StatelessWidget {
  const NextDoseLines({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String strength = doseStrengthText(context, occurrence);
    final String dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    final String how = occurrence.instructions == null
        ? dose
        : '$dose، ${occurrence.instructions}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: Semantics(
            button: true,
            child: InkWell(
              onTap: () =>
                  openMedication(context, circleId, occurrence, canManage),
              child: Row(
                children: [
                  const Icon(TafaqodPhosphorIcons.pill, size: 17),
                  const SizedBox(width: AppSpacing.tight),
                  Flexible(
                    child: Text(
                      '${occurrence.name} $strength',
                      style: text.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(
          how,
          semanticsLabel: spoken(how),
          textAlign: TextAlign.end,
          style: text.bodyMedium,
        ),
      ],
    );
  }
}
