import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_actions.dart';
import 'package:app/features/medications/presentation/widgets/snooze_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// One button system for every task (TaskButtonRole): «تم أخذها» across the
/// card, then «ذكّرني لاحقًا» and «تخطي» under it.
///
/// «تم أخذها» asks when the dose was taken and offers the moment it is
/// pressed, so the one button records a dose taken now and one taken
/// earlier; «تم أخذها في وقت سابق» was a button of its own before, and a dose
/// of an earlier day had no way to be marked taken now. «ذكّرني لاحقًا»
/// is only for a dose of today: a day that has passed cannot be put off.
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
      // A day of four doses shows four «تم أخذها»: read aloud they are the
      // same word, so the reader is told which medicine.
      answer: TaskButton(
        role: TaskButtonRole.answer,
        icon: CupertinoIcons.checkmark,
        label: say('medications.taken_short'),
        semanticLabel: '${say('medications.taken_short')}، ${occurrence.name}',
        onPressed: () =>
            takeDoseAtDifferentTime(context, occurrence, circleId: circleId),
      ),
      choices: <Widget>[
        if (isToday && circleId != null)
          SnoozeButton(occurrence: occurrence, circleId: circleId!),
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
