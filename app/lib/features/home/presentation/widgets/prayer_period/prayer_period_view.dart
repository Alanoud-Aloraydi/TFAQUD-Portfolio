import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entries.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_task_rows.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/prayer_icons.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/prayer_period_card.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/prayer_period_tile.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/prayer_period_title.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One prayer period as a card: its title and the [rows] opened under it.
class PrayerPeriodView extends StatelessWidget {
  const PrayerPeriodView({
    super.key,
    required this.prayer,
    required this.time,
    required this.current,
    required this.open,
    required this.rows,
    required this.circleId,
    required this.canManage,
    required this.hasPhoto,
    required this.now,
  });

  final Prayer prayer;
  final String time;
  final bool current;
  final bool open;
  final List<PeriodEntry> rows;
  final String circleId;
  final bool canManage;
  final bool hasPhoto;
  final DateTime now;

  @override
  Widget build(BuildContext context) => PrayerPeriodCard(
    current: current,
    child: PrayerPeriodTile(
      // A new day or a changed open state rebuilds the tile closed or open.
      key: ValueKey('${now.year}-${now.month}-${now.day}:${prayer.name}:$open'),
      icon: prayerIcon(prayer),
      current: current,
      expanded: open && rows.isNotEmpty,
      title: PrayerPeriodTitle(
        name: context.tr('prayer_times.${prayer.name}'),
        time: clockText(time),
        current: current,
        taskCount: rows.length,
      ),
      children: periodTaskRows(
        rows,
        circleId: circleId,
        canManage: canManage,
        hasPhoto: hasPhoto,
        now: now,
      ),
    ),
  );
}
