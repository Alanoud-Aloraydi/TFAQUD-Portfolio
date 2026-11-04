import 'dart:async';

import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_sections.dart';
import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/presentation/today_medication_view.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_components.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_today_section.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the today page UI.
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectedCircleBuilder(
      builder: (context, circle) {
        final now = riyadhNow();
        final date =
            "${context.tr('common.weekdays.${now.weekday}')} "
            "${now.day} ${context.tr('circles.months.${now.month}')}";
        return BlocBuilder<
          MedicationOccurrencesCubit,
          MedicationOccurrencesState
        >(
          builder: (context, doses) =>
              BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                builder: (context, prayers) => SingleChildScrollView(
                  padding: context.scrollPadding(
                    const EdgeInsets.all(AppSpacing.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LargeTitle(
                        title: context.tr('tab.today'),
                        subtitle: date,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _content(context, circle.id, doses, prayers, now),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    String circleId,
    MedicationOccurrencesState state,
    PrayerTimesState prayers,
    DateTime now,
  ) {
    final PrayerDay? day =
        prayers.day != null && DateUtils.isSameDay(prayers.day!.date, now)
        ? prayers.day
        : null;
    final medications = TodayMedicationView(
      state.status == MedicationOccurrencesStatus.loading ||
              state.status == MedicationOccurrencesStatus.failure
          ? const []
          : state.occurrences,
      now,
    );
    final taskState = context.watch<MeasurementTasksCubit>().state;
    final readingState = context.watch<MeasurementReadingsCubit>().state;
    final measurementTasks = taskState.tasks
        .where((task) => DateUtils.isSameDay(task.scheduledOn, now))
        .toList();
    final measurementReadings = readingState.readings;
    final appointmentState = context.watch<AppointmentsCubit>().state;
    final todayAppointments = appointmentState.appointments
        .where(
          (item) =>
              item.status == AppointmentStatus.scheduled &&
              DateUtils.isSameDay(item.scheduledOn, now),
        )
        .toList();
    final todayOccurrences = medications.todayOccurrences;
    final next = _nearestTask(
      now,
      state.occurrences,
      taskState.tasks,
      appointmentState.appointments,
    );
    final attention = medications.attention;
    final measurementAttention = MeasurementAttentionSection.count(
      measurementTasks,
      measurementReadings,
    );
    final failureKeys = <String>[
      if (state.status == MedicationOccurrencesStatus.failure)
        state.messageKey ?? 'error.unknown',
      if (taskState.status == MeasurementLoadStatus.failure)
        taskState.errorKey ?? 'error.unknown',
      if (readingState.status == MeasurementLoadStatus.failure)
        readingState.errorKey ?? 'error.unknown',
      if (appointmentState.status == AppointmentsLoadStatus.failure)
        appointmentState.errorKey ?? 'error.unknown',
      if (prayers.status == PrayerTimesStatus.failure)
        'prayer_times.unavailable',
    ];
    final String? loadErrorKey = failureKeys.isEmpty ? null : failureKeys.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.status == MedicationOccurrencesStatus.loading)
          const DoseRowSkeleton(withButtons: true),
        if (loadErrorKey != null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr(loadErrorKey), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    if (state.status == MedicationOccurrencesStatus.failure) {
                      unawaited(
                        context.read<MedicationOccurrencesCubit>().reload(),
                      );
                    }
                    if (taskState.status == MeasurementLoadStatus.failure) {
                      unawaited(context.read<MeasurementTasksCubit>().reload());
                    }
                    if (readingState.status == MeasurementLoadStatus.failure) {
                      unawaited(
                        context.read<MeasurementReadingsCubit>().reload(),
                      );
                    }
                    if (appointmentState.status ==
                        AppointmentsLoadStatus.failure) {
                      unawaited(
                        context.read<AppointmentsCubit>().load(circleId),
                      );
                    }
                    if (prayers.status == PrayerTimesStatus.failure) {
                      unawaited(context.read<PrayerTimesCubit>().reload());
                    }
                  },
                  child: Text(context.tr('auth.retry')),
                ),
              ],
            ),
          ),
        if (state.status == MedicationOccurrencesStatus.ready &&
            loadErrorKey == null &&
            todayOccurrences.isEmpty &&
            measurementTasks.isEmpty &&
            todayAppointments.isEmpty) ...[
          InsetText(context.tr('today_dashboard.no_tasks_today')),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (next != null) ...[
          _NextTaskCard(task: next, circleId: circleId, now: now),
          const SizedBox(height: AppSpacing.md),
        ] else if (state.status == MedicationOccurrencesStatus.ready &&
            loadErrorKey == null &&
            todayOccurrences.isNotEmpty &&
            attention.isEmpty &&
            measurementTasks.isEmpty &&
            todayAppointments.isEmpty) ...[
          InsetText(context.tr('today_dashboard.no_remaining_tasks')),
          const SizedBox(height: AppSpacing.xl),
        ],
        // One «يحتاج انتباهك» box: the doses, then the measurements.
        if (attention.isNotEmpty || measurementAttention > 0) ...[
          TodayMedicationAttentionSection(
            occurrences: attention,
            circleId: circleId,
            extraCount: measurementAttention,
            extra: measurementAttention > 0
                ? MeasurementAttentionSection(
                    tasks: measurementTasks,
                    readings: measurementReadings,
                    boxed: false,
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        _SectionTitle(context.tr('today_dashboard.schedule')),
        const SizedBox(height: AppSpacing.md),
        if (day != null) ...[
          InsetText(
            context.tr('prayer_times.city', args: [day.city]),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < Prayer.values.length; index++) ...[
            _PrayerPeriod(
              prayer: Prayer.values[index],
              time: day.times[Prayer.values[index]]!,
              nextTime: index + 1 < Prayer.values.length
                  ? day.times[Prayer.values[index + 1]]
                  : null,
              prayerTimes: day.times,
              occurrences: todayOccurrences,
              measurementTasks: measurementTasks,
              appointments: todayAppointments,
              circleId: circleId,
              now: now,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ] else if (todayOccurrences.isNotEmpty)
          for (final item in todayOccurrences)
            DoseOccurrenceCard(
              occurrence: item,
              showControls: false,
              timingState: medicationTimingState(item, now),
            ),
        if (day == null)
          for (final task in measurementTasks) MeasurementTaskRow(task: task),
        if (day == null)
          for (final item in todayAppointments)
            AppointmentTodayRow(value: item),
      ],
    );
  }
}

typedef _NextTask = ({
  DateTime at,
  DoseOccurrence? medication,
  MeasurementOccurrence? measurement,
  CareAppointment? appointment,
});

/// Selects the earliest open task from today's and future schedules.
_NextTask? _nearestTask(
  DateTime now,
  List<DoseOccurrence> medications,
  List<MeasurementOccurrence> measurements,
  List<CareAppointment> appointments,
) {
  final candidates = <_NextTask>[
    for (final item in medications)
      if (medicationIsNextTaskCandidate(item, now))
        (
          at: riyadhScheduledAt(item.scheduledOn, item.time).isBefore(now)
              ? now
              : riyadhScheduledAt(item.scheduledOn, item.time),
          medication: item,
          measurement: null,
          appointment: null,
        ),
    for (final item in measurements)
      if (item.record == null &&
          !riyadhScheduledAt(item.scheduledOn, item.time).isBefore(now))
        (
          at: riyadhScheduledAt(item.scheduledOn, item.time),
          medication: null,
          measurement: item,
          appointment: null,
        ),
    for (final item in appointments)
      if (item.status == AppointmentStatus.scheduled &&
          !riyadhScheduledAt(item.scheduledOn, item.time).isBefore(now))
        (
          at: riyadhScheduledAt(item.scheduledOn, item.time),
          medication: null,
          measurement: null,
          appointment: item,
        ),
  ]..sort((a, b) => a.at.compareTo(b.at));
  return candidates.firstOrNull;
}

/// Renders the next task card element of today page.
class _NextTaskCard extends StatelessWidget {
  const _NextTaskCard({
    required this.task,
    required this.circleId,
    required this.now,
  });
  final _NextTask task;
  final String circleId;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final medication = task.medication;
    final measurement = task.measurement;
    final appointment = task.appointment;
    final sameDay = DateUtils.isSameDay(task.at, now);
    if (medication != null && sameDay) {
      return TodayMedicationActionDose(
        occurrence: medication,
        circleId: circleId,
      );
    }
    final minutes = (task.at.difference(now).inSeconds + 59) ~/ 60;
    final relative = minutes < 60
        ? context.tr('today_dashboard.after_minutes', args: ['$minutes'])
        : minutes % 60 == 0
        ? context.tr('today_dashboard.after_hours', args: ['${minutes ~/ 60}'])
        : context.tr(
            'today_dashboard.after_hours_minutes',
            args: ['${minutes ~/ 60}', '${minutes % 60}'],
          );
    final title =
        medication?.name ??
        (measurement == null
            ? appointmentTitle(context, appointment!)
            : context.tr(
                measurement.kind == MeasurementKind.bp
                    ? 'measurements.bp'
                    : 'measurements.glucose',
              ));
    final time = medication?.time ?? measurement?.time ?? appointment!.time;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.textSupporting),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('today_dashboard.next_task'),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${context.tr('common.weekdays.${task.at.weekday}')} '
              '${formatMedicationDate(context, task.at)} · '
              '${formatMedicationTime(context, time)}',
            ),
            if (minutes < 2880)
              Text(relative, style: Theme.of(context).textTheme.titleMedium),
            if (appointment != null)
              Text(
                context.tr(
                  'appointments.companion_name',
                  args: [appointmentCompanionNames(context, appointment)],
                ),
              ),
            if (measurement != null && sameDay) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () async {
                  final saved = await showMeasurementReadingSheet(
                    context,
                    occurrence: measurement,
                  );
                  if (saved && context.mounted) {
                    context.read<MeasurementTasksCubit>().reload();
                  }
                },
                child: Text(context.tr('measurements.record_reading')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders the section title element of today page.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.headlineSmall);
}

/// Renders the prayer period element of today page.
class _PrayerPeriod extends StatelessWidget {
  const _PrayerPeriod({
    required this.prayer,
    required this.time,
    required this.nextTime,
    required this.prayerTimes,
    required this.occurrences,
    required this.measurementTasks,
    required this.appointments,
    required this.circleId,
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
    final formattedTime = formatMedicationTime(context, time);
    final photos = RepositoryProvider.of<PrivatePhotoRepository>(context);
    return FutureBuilder<bool>(
      future: Future.wait([
        for (final item in items)
          photos.load(ApiEndpoints.medicationPhoto(circleId, item.planId)),
      ]).then((values) => values.any((value) => value != null)),
      builder: (context, photoState) => Material(
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
                  now: now,
                  showThumbnail: photoState.data ?? false,
                )
              else if (entry.measurement case final task?)
                MeasurementTaskRow(task: task)
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
  Prayer.maghrib => TafaqodPhosphorIcons.cloudMoon,
  Prayer.isha => TafaqodPhosphorIcons.moonStars,
};
