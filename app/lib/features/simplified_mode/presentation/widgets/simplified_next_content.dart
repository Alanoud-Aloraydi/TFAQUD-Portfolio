import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/domain/entities/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_text.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:flutter/material.dart';

/// Inside the next card: the picture with its period on the corner, then
/// the words.
class SimplifiedNextContent extends StatelessWidget {
  const SimplifiedNextContent({
    super.key,
    required this.task,
    required this.day,
    required this.when,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «التالي، بعد ساعتين», or what the task was put off to.
  final String when;

  @override
  Widget build(BuildContext context) {
    final PrayerPeriod? period = simplifiedNextPeriod(task, day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(
          children: <Widget>[
            SimplifiedNextHero(task: task, day: day),
            if (period != null) SimplifiedNextPeriodBadge(period: period),
          ],
        ),
        SimplifiedNextText(task: task, day: day, when: when),
      ],
    );
  }
}

/// «بعد المغرب», the pill on the corner of the next card's picture.
class SimplifiedNextPeriodBadge extends StatelessWidget {
  const SimplifiedNextPeriodBadge({super.key, required this.period});

  final PrayerPeriod period;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 14,
      start: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: SimplifiedColors.surface,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          simplifiedPeriod(context, period),
          style: SimplifiedStyle.head(SimplifiedStyle.caption),
        ),
      ),
    );
  }
}

/// The mark of something done, in the colours of the detailed mode's «تم
/// أخذها»: a green check on the pale green, ringed in the same green so it
/// stands on any ground. The same on «تم، يعطيك العافية» and on the home's
/// «خلّصت مهام اليوم». Decorative: the words beside it say what was done.
class SimplifiedDoneMark extends StatelessWidget {
  const SimplifiedDoneMark({super.key, required this.size});

  /// The circle's width; the check is half of it.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SimplifiedColors.successTint,
        shape: BoxShape.circle,
        border: Border.all(color: SimplifiedColors.success, width: size / 36),
      ),
      child: Icon(
        ActionIcons.check,
        size: size / 2,
        color: SimplifiedColors.success,
      ),
    ),
  );
}
