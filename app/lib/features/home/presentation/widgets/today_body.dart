import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/section_header.dart';
import 'package:app/features/home/presentation/today_prayer_day.dart';
import 'package:app/features/home/presentation/today_snapshot.dart';
import 'package:app/features/home/presentation/widgets/today_attention.dart';
import 'package:app/features/home/presentation/widgets/today_schedule.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The box of what needs attention (overdue days included) and the day's
/// schedule under it.
class TodayBody extends StatelessWidget {
  const TodayBody({
    super.key,
    required this.snapshot,
    required this.circleId,
    required this.canManage,
  });

  final TodaySnapshot snapshot;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final prayers = context.watch<PrayerTimesCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (snapshot.needsAttention) ...<Widget>[
          TodayAttention(
            snapshot: snapshot,
            circleId: circleId,
            canManage: canManage,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        SectionHeader(context.tr('today_dashboard.schedule')),
        const SizedBox(height: AppSpacing.md),
        TodaySchedule(
          snapshot: snapshot,
          day: todayPrayerDay(prayers, snapshot.now),
          circleId: circleId,
          canManage: canManage,
        ),
      ],
    );
  }
}
