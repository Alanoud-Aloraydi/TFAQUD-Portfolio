import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_actions.dart';
import 'package:app/features/medications/presentation/widgets/snooze_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// One button system for every task (TaskButtonRole): each answer its own
/// colour and icon, all 48 high, two to a line of equal widths. «انأخذت»
/// and «ذكّرني لاحقًا» are only for a dose of today.
class DoseTaskButtons extends StatelessWidget {
  const DoseTaskButtons({
    super.key,
    required this.occurrence,
    required this.isToday,
    this.circleId,
  });

  final DoseOccurrence occurrence;
  final bool isToday;
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    String say(String key) => CareVoice.tr(context, circleId, key);
    return TaskButtonGrid(
      buttons: <Widget>[
        if (isToday)
          // A day of four doses shows four «انأخذت»: read aloud they are
          // the same word, so the reader is told which medicine.
          TaskButton(
            role: TaskButtonRole.answer,
            icon: CupertinoIcons.checkmark,
            label: say('medications.taken_short'),
            semanticLabel:
                '${say('medications.taken_short')}، ${occurrence.name}',
            onPressed: () =>
                takeDoseNow(context, occurrence, circleId: circleId),
          ),
        if (isToday && circleId != null)
          SnoozeButton(occurrence: occurrence, circleId: circleId!),
        TaskButton(
          role: TaskButtonRole.earlier,
          icon: CupertinoIcons.clock,
          label: say('medications.different_time_short'),
          onPressed: () =>
              takeDoseAtDifferentTime(context, occurrence, circleId: circleId),
        ),
        TaskButton(
          role: TaskButtonRole.skip,
          icon: CupertinoIcons.minus_circle,
          label: context.tr('medications.skip_short'),
          onPressed: () => skipDose(context, occurrence, circleId: circleId),
        ),
      ],
    );
  }
}
