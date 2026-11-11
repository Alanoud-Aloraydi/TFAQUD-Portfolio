import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:flutter/material.dart';

/// One card of the measurement attention box: what needs attention, why,
/// and the buttons that answer it.
class MeasurementAttentionCard extends StatelessWidget {
  const MeasurementAttentionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.dateText,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  /// The day of a missed task; null for a reading outside its target.
  final String? dateText;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: TodayRowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: text.titleSmall),
            if (dateText case final String date)
              Text(date, style: text.bodySmall),
            Text(subtitle, style: text.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: AppSpacing.sm, children: actions),
          ],
        ),
      ),
    );
  }
}
