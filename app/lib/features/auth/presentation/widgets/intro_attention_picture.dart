import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/features/medications/presentation/widgets/attention_dose_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Page 3: «يحتاج انتباهك» of «اليوم», with one dose gone past its time.
class IntroAttentionPicture extends StatelessWidget {
  const IntroAttentionPicture({super.key});

  @override
  Widget build(BuildContext context) {
    String tr(String key) => context.tr(key);
    final Color red = context.tokens.error;
    return AttentionBox(
      title: tr('today_dashboard.attention'),
      count: 1,
      // The white card of a late dose, as AttentionMedicationCard draws it.
      child: TodayRowCard(
        child: Column(
          spacing: AppSpacing.sm,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.tight,
              children: <Widget>[
                CircleAvatar(
                  radius: 17,
                  backgroundColor: red.withValues(alpha: .08),
                  child: Icon(TafaqodPhosphorIcons.pill, color: red, size: 18),
                ),
                Expanded(
                  child: AttentionDoseText(
                    title: tr('intro.demo.dose'),
                    when: tr('intro.demo.dose_when'),
                    how: tr('intro.demo.dose_how'),
                  ),
                ),
              ],
            ),
            TaskButtonGrid(
              answer: TaskButton(
                role: TaskButtonRole.answer,
                icon: CupertinoIcons.checkmark,
                label: tr('medications.taken_short_other'),
                onPressed: () {},
              ),
              choices: <Widget>[
                TaskButton(
                  role: TaskButtonRole.skip,
                  icon: CupertinoIcons.minus_circle,
                  label: tr('medications.skip_short'),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
