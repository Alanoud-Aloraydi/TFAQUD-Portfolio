import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_actions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// «أُخذت» on the compact dose controls.
Widget doseTakenButton(
  BuildContext context, {
  required DoseOccurrence occurrence,
  required ButtonStyle style,
  String? circleId,
}) {
  // A day of four doses shows four «أُخذت» buttons. Read
  // aloud they are the same word, so the reader cannot
  // tell which medicine is being recorded: the label
  // names it.
  return MergeSemantics(
    child: Semantics(
      label: spoken(
        '${CareVoice.tr(context, circleId, 'medications.taken_short')}'
        '، ${occurrence.name}',
      ),
      child: FilledButton.icon(
        style: style,
        onPressed: () =>
            takeDoseNow(context, occurrence, circleId: circleId),
        icon: const Icon(CupertinoIcons.checkmark, size: 16),
        // The words are on the Semantics above; excluded
        // here they are not said twice.
        label: ExcludeSemantics(
          child: Text(
            CareVoice.tr(context, circleId, 'medications.taken_short'),
          ),
        ),
      ),
    ),
  );
}
