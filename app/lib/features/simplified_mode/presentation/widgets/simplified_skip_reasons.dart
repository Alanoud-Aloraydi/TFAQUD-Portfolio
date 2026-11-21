import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dark_choice.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const Map<String, DoseSkipReason> _reasons = <String, DoseSkipReason>{
  'simplified_mode.skip_forgotten': DoseSkipReason.forgotten,
  'simplified_mode.skip_unavailable': DoseSkipReason.unavailable,
  'simplified_mode.skip_side_effects': DoseSkipReason.sideEffects,
};

/// Three reasons in the patient's own words, then «سبب آخر» ([onOther]).
/// All of them wait while an answer is being saved.
List<Widget> simplifiedSkipReasons(
  BuildContext context, {
  required bool saving,
  required void Function(DoseSkipReason reason) onReason,
  required VoidCallback onOther,
}) {
  Widget choice(String key, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SimplifiedDarkChoice(
      label: context.tr(key),
      onTap: saving ? null : onTap,
    ),
  );
  return <Widget>[
    for (final MapEntry<String, DoseSkipReason> reason in _reasons.entries)
      choice(reason.key, () => onReason(reason.value)),
    choice('simplified_mode.skip_other', onOther),
  ];
}
