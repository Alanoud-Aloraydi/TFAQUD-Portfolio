import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/localization/greeting.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/widgets/today_snapshot.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    // The name as the home data has it, so a name saved on «حسابي» shows
    // as soon as the home is read again, not at the next minute.
    final String? name = context.select<HomeCubit, String?>(
      (HomeCubit cubit) => cubit.state.data?.displayName,
    );
    final String weekday = context.tr('common.weekdays.${now.weekday}');
    final String date = calendarDate(context, now, year: false);
    return LargeTitle(
      title: greeting(
        context,
        now,
        name,
        fajr: day?.times[Prayer.fajr],
        dhuhr: day?.times[Prayer.dhuhr],
      ),
      subtitle: '$weekday $date',
      subtitleTrailing: weather,
    );
  }
}
