import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_sections.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_today_section.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/today_medication_view.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_components.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One prayer period of «اليوم»: its name and time, and the doses, readings
/// and visits that fall nearest to it. The period the patient is in is marked
/// and open, like one that needs attention.
class TodayPrayerPeriod extends StatelessWidget {
  const TodayPrayerPeriod({
    super.key,
    required this.prayer,
    required this.time,
    required this.nextTime,
    required this.prayerTimes,
    required this.occurrences,
    required this.measurementTasks,
    required this.appointments,
    required this.circleId,
    required this.canManage,
    required this.now,
  });
  final Prayer prayer;
  final String time;
  final String? nextTime;
  final Map<Prayer, String> prayerTimes;
  final List<DoseOccurrence> occurrences;
  final List<MeasurementOccurrence> measurementTasks;
  final List<CareAppointment> appointments;
  final String circleId;
  final bool canManage;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final items = occurrences
        .where((item) => _nearestPrayer(item.time, prayerTimes) == prayer)
        .toList();
    final measures = measurementTasks
        .where((item) => _nearestPrayer(item.time, prayerTimes) == prayer)
        .toList();
    final visits = appointments
        .where((item) => _nearestPrayer(item.time, prayerTimes) == prayer)
        .toList();
    final entries =
        <
            ({
              String time,
              DoseOccurrence? medication,
              MeasurementOccurrence? measurement,
              CareAppointment? appointment,
            })
          >[
            for (final item in items)
              (
                time: item.time,
                medication: item,
                measurement: null,
                appointment: null,
              ),
            for (final item in measures)
              (
                time: item.time,
                medication: null,
                measurement: item,
                appointment: null,
              ),
            for (final item in visits)
              (
                time: item.time,
                medication: null,
                measurement: null,
                appointment: item,
              ),
          ]
          ..sort((first, second) => first.time.compareTo(second.time));
    final minute = now.hour * 60 + now.minute;
    final parts = time.split(':');
    final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final endParts = nextTime?.split(':');
    final end = endParts == null
        ? 1440
        : int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final current = minute >= start && minute < end;
    final summary = MedicationPeriodSummary(items, now);
    final missedMeasurements = measures
        .where((item) => item.status == MeasurementStatus.missed)
        .length;
    final expanded =
        current ||
        summary.attentionCount > 0 ||
        missedMeasurements > 0 ||
        visits.isNotEmpty;
    final title = context.tr('prayer_times.${prayer.name}');
    final formattedTime = clockText(time);
    return PhotoProbe(
      circleId: circleId,
      planIds: [for (final item in items) item.planId],
      builder: (context, hasPhoto) => Material(
        color: AppSemanticColors.surfaceContent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(
            color: current
                ? AppSemanticColors.accentWarm
                : AppSemanticColors.transparent,
            width: current ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: ValueKey(
            '${now.year}-${now.month}-${now.day}:${prayer.name}:$expanded',
          ),
          initiallyExpanded: expanded && entries.isNotEmpty,
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: AppSemanticColors.textSupporting,
          collapsedIconColor: AppSemanticColors.textSupporting,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          leading: Icon(
            _prayerIcon(prayer),
            color: current
                ? AppSemanticColors.doseDueMarker
                : AppSemanticColors.textSupporting,
          ),
          title: Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Spacer(),
              if (current)
                CompactStatusBadge(
                  text: context.tr('today_dashboard.current_period'),
                  background: AppSemanticColors.surfaceAttention,
                  foreground: AppSemanticColors.statusWarning,
                )
              else if (summary.attentionCount + missedMeasurements > 0)
                CompactStatusBadge(
                  text: (summary.attentionCount + missedMeasurements)
                      .toString(),
                  background: summary.hasMissed || missedMeasurements > 0
                      ? Theme.of(context).colorScheme.errorContainer
                      : AppSemanticColors.surfaceAttention,
                  foreground: summary.hasMissed || missedMeasurements > 0
                      ? context.tokens.errorText
                      : context.tokens.warningText,
                )
              else if (summary.allResolved &&
                  measures.isEmpty &&
                  visits.isEmpty)
                MedicationPeriodMarks(occurrences: items, now: now)
              else if (entries.isNotEmpty)
                CompactStatusBadge(
                  text: '${entries.length}',
                  background: AppSemanticColors.surfaceContent,
                  foreground: AppSemanticColors.textPrimary,
                ),
            ],
          ),
          children: [
            for (final entry in entries) ...[
              if (entry.medication case final item?)
                TodayMedicationPrayerDoseRow(
                  occurrence: item,
                  circleId: circleId,
                  canManage: canManage,
                  now: now,
                  showThumbnail: hasPhoto,
                )
              else if (entry.measurement case final task?)
                MeasurementTaskRow(task: task, now: now, circleId: circleId)
              else if (entry.appointment case final visit?)
                AppointmentTodayRow(value: visit),
              if (entry != entries.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tells its [builder] whether any of the medicines [planIds] of [circleId]
/// has a photo. The photos are looked up when the plans change, not on every
/// rebuild (the page rebuilds each minute).
class PhotoProbe extends StatefulWidget {
  const PhotoProbe({
    super.key,
    required this.circleId,
    required this.planIds,
    required this.builder,
  });

  final String circleId;
  final List<String> planIds;
  final Widget Function(BuildContext context, bool hasPhoto) builder;

  @override
  State<PhotoProbe> createState() => _PhotoProbeState();
}

class _PhotoProbeState extends State<PhotoProbe> {
  bool _hasPhoto = false;
  int _lookup = 0;

  @override
  void initState() {
    super.initState();
    _look();
  }

  @override
  void didUpdateWidget(PhotoProbe old) {
    super.didUpdateWidget(old);
    if (old.circleId != widget.circleId ||
        !listEquals(old.planIds, widget.planIds)) {
      _look();
    }
  }

  void _look() {
    final photos = RepositoryProvider.of<PrivatePhotoRepository>(context);
    final int lookup = ++_lookup;
    final String circleId = widget.circleId;
    Future.wait([
      for (final String id in widget.planIds)
        photos.load(ApiEndpoints.medicationPhoto(circleId, id)),
    ]).then((values) {
      final bool found = values.any((value) => value != null);
      if (mounted && lookup == _lookup && found != _hasPhoto) {
        setState(() => _hasPhoto = found);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _hasPhoto);
}

Prayer _nearestPrayer(String time, Map<Prayer, String> prayerTimes) {
  int minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  final target = minutes(time);
  return Prayer.values.reduce(
    (best, item) =>
        (minutes(prayerTimes[item]!) - target).abs() <
            (minutes(prayerTimes[best]!) - target).abs()
        ? item
        : best,
  );
}

IconData _prayerIcon(Prayer prayer) => switch (prayer) {
  Prayer.fajr => TafaqodPhosphorIcons.sunHorizon,
  Prayer.dhuhr => TafaqodPhosphorIcons.sun,
  Prayer.asr => TafaqodPhosphorIcons.sunDim,
  // Phosphor's sun-horizon glyph is left-right symmetric, so mirroring it
  // for Maghrib looked identical to Fajr. Maghrib is still about the sun
  // (not the moon, which is Isha), so a fading/clouded sun shape instead.
  Prayer.maghrib => TafaqodPhosphorIcons.cloudSun,
  Prayer.isha => TafaqodPhosphorIcons.moonStars,
};
