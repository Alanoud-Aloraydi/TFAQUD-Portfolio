import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

class SimplifiedSchedulePeriodHeader extends StatelessWidget {
  const SimplifiedSchedulePeriodHeader({super.key, required this.period});

  final PrayerPeriod period;

  /// What the header says: «بعد المغرب. المساء».
  static List<String> lines(BuildContext context, PrayerPeriod period) =>
      <String>[
        simplifiedPeriod(context, period),
        simplifiedPeriodHint(context, period),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: SimplifiedStyle.chip,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: <Widget>[
          Text(
            simplifiedPeriod(context, period),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          Text(
            simplifiedPeriodHint(context, period),
            style: SimplifiedStyle.text(SimplifiedStyle.caption),
          ),
        ],
      ),
    );
  }
}
