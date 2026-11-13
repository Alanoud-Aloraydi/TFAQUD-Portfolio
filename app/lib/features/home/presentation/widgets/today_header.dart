import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/features/home/presentation/today_prayer_day.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «صباح الخير، ياسر» from Fajr, «مساء الخير، ياسر» from Asr, with the
/// patient's date under it and [weather] beside the date; the tab keeps
/// «اليوم».
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
    final String month = context.tr('circles.months.${now.month}');
    return LargeTitle(
      title: greeting(
        context,
        now,
        CareVoice.viewerName,
        fajr: day?.times[Prayer.fajr],
        asr: day?.times[Prayer.asr],
      ),
      subtitle: '$weekday ${now.day} $month',
      subtitleTrailing: weather,
    );
  }
}
