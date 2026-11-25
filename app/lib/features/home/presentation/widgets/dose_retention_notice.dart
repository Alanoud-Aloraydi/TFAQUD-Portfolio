import 'package:app/app/services/dose_retention_memory.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/localization/greeting.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/home/presentation/cubit/dose_retention_cubit.dart';
import 'package:app/features/home/presentation/widgets/dose_retention_actions.dart';
import 'package:app/features/home/presentation/widgets/today_snapshot.dart';
import 'package:app/features/medications/domain/entities/dose_retention.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// On «اليوم», five days before the doses of a day are deleted for good
/// (they are kept three months): what goes, and the way to export it
/// first. Nothing once exported or set aside, until the next days.
class DoseRetentionNotice extends StatelessWidget {
  const DoseRetentionNotice({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    // Its own answer for each circle shown.
    key: ValueKey<String>(circleId),
    create: (_) =>
        DoseRetentionCubit(const DoseRetentionMemory(), circleId)..load(),
    child: BlocBuilder<DoseRetentionCubit, DoseRetentionRead>(
      builder: (BuildContext context, DoseRetentionRead memory) {
        final DateTime? through = memory.read
            ? DoseRetention.goingThrough(
                PatientClockScope.of(context).today(),
                context.watch<MedicationsCubit>().state.plans,
                memory.settled,
              )
            : null;
        if (through == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: AttentionBox(
            title: context.tr('dose_retention.title'),
            child: DoseRetentionActions(circleId: circleId, through: through),
          ),
        );
      },
    ),
  );
}

/// «صباح الخير، ياسر» from Fajr, «مساء الخير، ياسر» from Dhuhr, with
/// the patient's date under it and [weather] beside the date; the tab
/// keeps «اليوم».
class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key, required this.now, this.weather});

  final DateTime now;
  final Widget? weather;

  @override
  Widget build(BuildContext context) {
    final PrayerDay? day = todayPrayerDay(
      context.watch<PrayerTimesCubit>().state,
      now,
    );
    final String weekday = context.tr('common.weekdays.${now.weekday}');
    final String date = calendarDate(context, now, year: false);
    return LargeTitle(
      title: greeting(
        context,
        now,
        CareVoice.viewerName,
        fajr: day?.times[Prayer.fajr],
        dhuhr: day?.times[Prayer.dhuhr],
      ),
      subtitle: '$weekday $date',
      subtitleTrailing: weather,
    );
  }
}
