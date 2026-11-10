import 'dart:async';

import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/layout/section_header.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_sections.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/home/presentation/widgets/today_prayer_period.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_today_section.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/medications/presentation/today_medication_view.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_components.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «اليوم»: the greeting, what needs attention, the next task and the day's
/// schedule by prayer period, all on the patient's clock.
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
        final now = PatientClockScope.of(context).now();
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
                      // «صباح الخير، ياسر» from Fajr, «مساء الخير، ياسر»
                      // from Asr; the tab keeps «اليوم».
                      LargeTitle(
                        title: greeting(
                          context,
                          now,
                          CareVoice.viewerName,
                          fajr: _today(prayers, now)?.times[Prayer.fajr],
                          asr: _today(prayers, now)?.times[Prayer.asr],
                        ),
                        subtitle: date,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _content(
                        context,
                        circle.id,
                        circle.canManageMedications,
                        doses,
                        prayers,
                        now,
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }

  /// Today's prayer times, or null while they load (or are yesterday's).
  static PrayerDay? _today(PrayerTimesState prayers, DateTime now) =>
      prayers.day != null && DateUtils.isSameDay(prayers.day!.date, now)
      ? prayers.day
      : null;

  Widget _content(
    BuildContext context,
    String circleId,
    bool canManage,
    MedicationOccurrencesState state,
    PrayerTimesState prayers,
    DateTime now,
  ) {
    final PrayerDay? day = _today(prayers, now);
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
    final next = nearestTask(
      now,
      state.occurrences,
      taskState.tasks,
      appointmentState.appointments,
    );
    final attention = medications.attention;
    final measurementAttention = MeasurementAttentionSection.count(
      measurementTasks,
      measurementReadings,
      PatientClockScope.of(context),
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
          EmptyStateNote(
            CareVoice.tr(context, circleId, 'today_dashboard.no_tasks_today'),
            actionLabel: context.tr('add.title'),
            onAction: () => showHomeAddSheet(context, circleId: circleId),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (next != null) ...[
          NextTaskCard(
            task: next,
            circleId: circleId,
            canManage: canManage,
            now: now,
          ),
          const SizedBox(height: AppSpacing.md),
        ] else if (state.status == MedicationOccurrencesStatus.ready &&
            loadErrorKey == null &&
            todayOccurrences.isNotEmpty &&
            attention.isEmpty &&
            measurementTasks.isEmpty &&
            todayAppointments.isEmpty) ...[
          EmptyStateNote(
            context.tr('today_dashboard.no_remaining_tasks'),
            actionLabel: context.tr('add.title'),
            onAction: () => showHomeAddSheet(context, circleId: circleId),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        // One «يحتاج انتباهك» box: the doses, then the measurements.
        if (attention.isNotEmpty || measurementAttention > 0) ...[
          TodayMedicationAttentionSection(
            occurrences: attention,
            circleId: circleId,
            canManage: canManage,
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
        SectionHeader(context.tr('today_dashboard.schedule')),
        const SizedBox(height: AppSpacing.md),
        if (day != null) ...[
          InsetText(
            context.tr('prayer_times.city', args: [day.city]),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < Prayer.values.length; index++) ...[
            TodayPrayerPeriod(
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
              canManage: canManage,
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
              circleId: circleId,
            ),
        if (day == null)
          for (final task in measurementTasks)
            MeasurementTaskRow(task: task, now: now, circleId: circleId),
        if (day == null)
          for (final item in todayAppointments)
            AppointmentTodayRow(value: item),
      ],
    );
  }
}
