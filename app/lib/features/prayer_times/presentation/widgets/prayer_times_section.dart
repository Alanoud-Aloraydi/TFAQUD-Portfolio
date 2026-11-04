import 'dart:async';

import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the prayer times section UI.
class PrayerTimesSection extends StatefulWidget {
  const PrayerTimesSection({super.key});

  @override
  State<PrayerTimesSection> createState() => _PrayerTimesSectionState();
}

class _PrayerTimesSectionState extends State<PrayerTimesSection> {
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
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.tr('prayer_times.title'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          switch (state.status) {
            PrayerTimesStatus.loading => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
            PrayerTimesStatus.failure => _Failure(
              onRetry: context.read<PrayerTimesCubit>().reload,
            ),
            PrayerTimesStatus.ready => _PrayerList(day: state.day!),
          },
        ],
      ),
    );
  }
}

/// Renders the failure element of prayer times section.
class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(context.tr('prayer_times.unavailable'))),
          TextButton(onPressed: onRetry, child: Text(context.tr('auth.retry'))),
        ],
      ),
    );
  }
}

/// Renders the prayer list element of prayer times section.
class _PrayerList extends StatelessWidget {
  const _PrayerList({required this.day});

  final PrayerDay day;

  @override
  Widget build(BuildContext context) {
    final next = day.nextPrayer(DateTime.now());
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.tr('prayer_times.city', args: <String>[day.city]),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: <Widget>[
              for (final prayer in Prayer.values) ...<Widget>[
                if (prayer != Prayer.fajr)
                  Divider(height: 1, color: colors.outlineVariant),
                _PrayerRow(
                  prayer: prayer,
                  time: day.times[prayer]!,
                  isNext: prayer == next,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('prayer_times.method'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Renders the prayer row element of prayer times section.
class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.time,
    required this.isNext,
  });

  final Prayer prayer;
  final String time;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final parts = time.split(':');
    final formatted = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              context.tr('prayer_times.${prayer.name}'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (isNext) ...<Widget>[
            Text(
              context.tr('prayer_times.next'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Text(formatted, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
