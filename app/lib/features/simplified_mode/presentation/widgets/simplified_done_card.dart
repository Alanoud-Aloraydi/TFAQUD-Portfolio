import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SimplifiedDoneCard extends StatelessWidget {
  const SimplifiedDoneCard({super.key, required this.schedule});

  final TodaySchedule schedule;

  /// What the card says, in its order.
  static List<String> lines(BuildContext context, TodaySchedule schedule) {
    final (String count, String? tomorrow) = _counts(context, schedule);
    return <String>[context.tr('simplified_mode.all_done'), count, ?tomorrow];
  }

  /// «3 من 3 اليوم», and the first dose of tomorrow when there is one.
  static (String, String?) _counts(
    BuildContext context,
    TodaySchedule schedule,
  ) => (
    context.tr(
      'simplified_mode.done_count',
      args: <String>['${schedule.doneCount}', '${schedule.total}'],
    ),
    switch (schedule.firstDoseTomorrow) {
      final dose? => context.tr(
        'simplified_mode.first_dose_tomorrow',
        args: <String>[simplifiedTime(context, dose.time)],
      ),
      null => null,
    },
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: lines(context, schedule).join('، '),
      excludeSemantics: true,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final (String count, String? tomorrow) = _counts(context, schedule);
    return SimplifiedCard(
      child: Column(
        children: <Widget>[
          const CircleAvatar(
            radius: 36,
            backgroundColor: SimplifiedStyle.accentTint,
            child: Icon(
              AppIcons.check,
              size: 40,
              color: SimplifiedStyle.success,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('simplified_mode.all_done'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(26),
          ),
          const SizedBox(height: 6),
          Text(
            tomorrow == null ? count : '$count · $tomorrow',
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              weight: AppTextTheme.medium,
            ),
          ),
        ],
      ),
    );
  }
}
