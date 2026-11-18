import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_lines.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_mark.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SimplifiedDoneCard extends StatelessWidget {
  const SimplifiedDoneCard({super.key, required this.schedule});

  final TodaySchedule schedule;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: spoken(simplifiedDoneLines(context, schedule).join('، ')),
      excludeSemantics: true,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final (String count, String? tomorrow) = simplifiedDoneCounts(
      context,
      schedule,
    );
    return SimplifiedCard(
      child: Column(
        children: <Widget>[
          const SimplifiedDoneMark(size: 72),
          const SizedBox(height: 12),
          Text(
            context.tr('simplified_mode.all_done'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(26),
          ),
          const SizedBox(height: 6),
          Text(
            tomorrow == null ? count : '$count، $tomorrow',
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
