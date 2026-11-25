import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The mark, «تم، شكرًا», what was saved and, for a reading, what it means.
class SimplifiedDoneContent extends StatelessWidget {
  const SimplifiedDoneContent({
    super.key,
    required this.saved,
    required this.verdict,
  });

  final String saved;
  final MeasurementVerdict? verdict;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SimplifiedDoneMark(size: 144),
        const SizedBox(height: 32),
        Text(
          context.tr('simplified_mode.done_title'),
          style: SimplifiedStyle.head(38),
        ),
        const SizedBox(height: 8),
        Text(
          saved,
          textAlign: TextAlign.center,
          style: SimplifiedStyle.text(
            SimplifiedStyle.title,
            weight: AppTextTheme.medium,
          ),
        ),
        // The reading is worth little without what it
        // means, which is the whole reason to measure.
        if (verdict case final MeasurementVerdict said)
          SimplifiedDoneVerdictRow(verdict: said),
      ],
    );
  }
}

/// What the saved reading means, in a word beside its mark.
class SimplifiedDoneVerdictRow extends StatelessWidget {
  const SimplifiedDoneVerdictRow({super.key, required this.verdict});

  final MeasurementVerdict verdict;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(child: Icon(verdict.level.icon, size: 28)),
          const SizedBox(width: 8),
          Text(
            verdict.label,
            style: SimplifiedStyle.head(SimplifiedStyle.headline),
          ),
        ],
      ),
    );
  }
}
