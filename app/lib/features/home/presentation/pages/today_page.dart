import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/home/presentation/widgets/today_dose_window.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_card.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:app/features/medications/presentation/widgets/medication_state_view.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        final now = DateTime.now().toUtc().add(const Duration(hours: 3));
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
                      _content(
                        context,
                        doses,
                        prayers.day != null &&
                                DateUtils.isSameDay(prayers.day!.date, now)
                            ? prayers.day
                            : null,
                        now,
                      ),
                      if (prayers.status == PrayerTimesStatus.failure)
                        TextButton(
                          onPressed: context.read<PrayerTimesCubit>().reload,
                          child: Text(context.tr('prayer_times.unavailable')),
                        ),
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
    MedicationOccurrencesState state,
    PrayerDay? day,
    DateTime now,
  ) {
    if (state.status == MedicationOccurrencesStatus.loading) {
      return const DoseRowSkeleton(withButtons: true);
    }
    if (state.status == MedicationOccurrencesStatus.failure) {
      return MedicationFailureView(
        messageKey: state.messageKey!,
        onRetry: context.read<MedicationOccurrencesCubit>().reload,
      );
    }
    final occurrences = [...state.occurrences]
      ..sort((a, b) => a.time.compareTo(b.time));
    final next = occurrences.where((item) {
      final status = _status(item, now);
      return status == DoseTimingState.upcoming ||
          status == DoseTimingState.due ||
          status == DoseTimingState.late;
    }).firstOrNull;
    final attention = occurrences.where((item) {
      final status = _status(item, now);
      return item != next &&
          item.record == null &&
          (status == DoseTimingState.late || status == DoseTimingState.missed);
    }).toList();
    final takenToday =
        occurrences
            .where(
              (item) =>
                  item.record?.outcome == DoseOutcome.taken &&
                  item.record?.takenAt != null,
            )
            .toList()
          ..sort((a, b) => a.record!.takenAt!.compareTo(b.record!.takenAt!));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (occurrences.isEmpty) ...[
          Text(context.tr('today_dashboard.no_tasks_today')),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (next != null) ...[
          _ActionDose(
            occurrence: next,
            prominent: true,
            day: day,
            lastTaken: takenToday
                .where((item) => item.planId == next.planId)
                .lastOrNull,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ] else if (attention.isEmpty) ...[
          Text(context.tr('today_dashboard.no_remaining_tasks')),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (attention.isNotEmpty) ...[
          _AttentionSection(occurrences: attention),
          const SizedBox(height: AppSpacing.xl),
        ],
        _SectionTitle(context.tr('today_dashboard.schedule')),
        const SizedBox(height: AppSpacing.md),
        if (day != null) ...[
          Text(
            context.tr('prayer_times.city', args: [day.city]),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < Prayer.values.length; index++) ...[
            _PrayerPeriod(
              prayer: Prayer.values[index],
              time: day.times[Prayer.values[index]]!,
              isFirst: index == 0,
              nextTime: index + 1 < Prayer.values.length
                  ? day.times[Prayer.values[index + 1]]
                  : null,
              occurrences: occurrences,
              now: now,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ] else if (occurrences.isNotEmpty)
          for (final item in occurrences)
            DoseOccurrenceCard(
              occurrence: item,
              showControls: false,
              timingState: _status(item, now),
            ),
      ],
    );
  }
}

DoseTimingState? _status(DoseOccurrence item, DateTime now) {
  if (item.record != null) return null;
  final parts = item.time.split(':');
  final scheduled = DateTime.utc(
    item.scheduledOn.year,
    item.scheduledOn.month,
    item.scheduledOn.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
  if (now.isBefore(scheduled)) return DoseTimingState.upcoming;
  final minutes = now.difference(scheduled).inMinutes;
  if (minutes < 15) return DoseTimingState.due;
  if (minutes < item.missedAfterMinutes) return DoseTimingState.late;
  return DoseTimingState.missed;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.headlineSmall);
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({required this.occurrences});
  final List<DoseOccurrence> occurrences;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppSemanticColors.surfaceAttention,
      border: Border.all(color: AppSemanticColors.borderAttention),
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: ExpansionTile(
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.inset),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.inset,
        0,
        AppSpacing.inset,
        AppSpacing.sm,
      ),
      title: Text(
        context.tr(
          'today_dashboard.attention_count',
          args: [occurrences.length.toString()],
        ),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppSemanticColors.statusWarning),
      ),
      children: [
        for (final item in occurrences) ...[
          _ActionDose(occurrence: item),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    ),
  );
}

class _ActionDose extends StatelessWidget {
  const _ActionDose({
    required this.occurrence,
    this.prominent = false,
    this.day,
    this.lastTaken,
  });
  final DoseOccurrence occurrence;
  final bool prominent;
  final PrayerDay? day;
  final DoseOccurrence? lastTaken;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final status = _status(occurrence, now);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: prominent
          ? BoxDecoration(
              color: colors.surface,
              border: Border.all(
                color: AppSemanticColors.textSupporting,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
            )
          : AppSurfaces.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (prominent) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(switch (status) {
                      DoseTimingState.due => 'today_dashboard.due_title',
                      DoseTimingState.late => 'today_dashboard.late_title',
                      _ => 'today_dashboard.next',
                    }),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (day != null) Text(_period(context, day!)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (prominent)
            _NextDoseInfo(occurrence: occurrence)
          else
            DoseOccurrenceCard(
              occurrence: occurrence,
              showControls: false,
              timingState: status,
            ),
          if (prominent && lastTaken != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _lastTakenText(context, lastTaken!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (prominent) ...[
            const SizedBox(height: AppSpacing.sm),
            TodayDoseWindow(occurrence: occurrence, now: now),
            const SizedBox(height: AppSpacing.md),
          ],
          DoseRecordControls(occurrence: occurrence, compact: true),
        ],
      ),
    );
  }

  String _period(BuildContext context, PrayerDay prayerDay) {
    final prayer =
        Prayer.values
            .where(
              (item) => prayerDay.times[item]!.compareTo(occurrence.time) <= 0,
            )
            .lastOrNull ??
        Prayer.fajr;
    return context.tr(
      'today_dashboard.prayer_period',
      args: [context.tr('prayer_times.${prayer.name}')],
    );
  }

  String _lastTakenText(BuildContext context, DoseOccurrence item) {
    final taken = item.record!.takenAt!.toUtc().add(const Duration(hours: 3));
    final time =
        '${taken.hour.toString().padLeft(2, '0')}:'
        '${taken.minute.toString().padLeft(2, '0')}';
    return context.tr(
      'today_dashboard.last_taken',
      args: [
        formatMedicationTime(context, time),
        formatMedicationNumber(item.doseValue),
        context.tr('medications.unit.${item.doseUnit.name}'),
      ],
    );
  }
}

class _NextDoseInfo extends StatelessWidget {
  const _NextDoseInfo({required this.occurrence});

  final DoseOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final strength =
        '${formatMedicationNumber(occurrence.strengthValue)} '
        '${occurrence.strengthUnit.apiValue}';
    final dose = context.tr(
      'medications.dose',
      args: [
        formatMedicationNumber(occurrence.doseValue),
        context.tr('medications.unit.${occurrence.doseUnit.name}'),
      ],
    );
    return Row(
      children: [
        Text(
          formatMedicationTime(context, occurrence.time),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${occurrence.name} $strength',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                occurrence.instructions == null
                    ? dose
                    : '$dose · ${occurrence.instructions}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrayerPeriod extends StatelessWidget {
  const _PrayerPeriod({
    required this.prayer,
    required this.time,
    required this.isFirst,
    required this.nextTime,
    required this.occurrences,
    required this.now,
  });
  final Prayer prayer;
  final String time;
  final bool isFirst;
  final String? nextTime;
  final List<DoseOccurrence> occurrences;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final items = occurrences
        .where(
          (item) =>
              (isFirst || item.time.compareTo(time) >= 0) &&
              (nextTime == null || item.time.compareTo(nextTime!) < 0),
        )
        .toList();
    final minute = now.hour * 60 + now.minute;
    final parts = time.split(':');
    final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final endParts = nextTime?.split(':');
    final end = endParts == null
        ? 1440
        : int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final current = minute >= start && minute < end;
    final attention = items.any((item) {
      final status = _status(item, now);
      return status == DoseTimingState.late ||
          status == DoseTimingState.missed ||
          item.record?.outcome == DoseOutcome.skipped;
    });
    final expanded = current || attention;
    final title = context.tr('prayer_times.${prayer.name}');
    final formattedTime = formatMedicationTime(context, time);
    return Material(
      color: AppSemanticColors.surfaceContent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: current
              ? AppSemanticColors.accentWarm
              : AppSemanticColors.borderSubtle,
          width: current ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: items.isEmpty
          ? ListTile(
              leading: const Icon(AppIcons.clock),
              title: Text(title),
              subtitle: Text(context.tr('today_dashboard.no_period_doses')),
              trailing: Text(formattedTime),
            )
          : ExpansionTile(
              key: ValueKey(
                '${now.year}-${now.month}-${now.day}:${prayer.name}',
              ),
              initiallyExpanded: expanded,
              leading: Icon(
                current ? AppIcons.house : AppIcons.clock,
              ),
              title: Text(title),
              subtitle: Text(
                context.tr(
                  'today_dashboard.dose_count',
                  args: [items.length.toString()],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(formattedTime),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(AppIcons.caretDown),
                ],
              ),
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: DoseOccurrenceCard(
                      occurrence: item,
                      showControls: false,
                      timingState: _status(item, now),
                    ),
                  ),
              ],
            ),
    );
  }
}
