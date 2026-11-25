import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dark_choice.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «سبب آخر»: the patient writes the reason (250 characters at most, and
/// it may stay empty), then «سجّل» records the dose as not taken.
List<Widget> simplifiedSkipOther(
  BuildContext context, {
  required TextEditingController note,
  required VoidCallback? onSave,
}) {
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: SimplifiedColors.ink, width: 2),
  );
  return <Widget>[
    TextField(
      controller: note,
      autofocus: true,
      minLines: 2,
      maxLines: 4,
      maxLength: 250,
      inputFormatters: const [CodePointLengthFormatter(250)],
      style: SimplifiedStyle.text(
        SimplifiedStyle.body,
        color: SimplifiedColors.ink,
        weight: AppTextTheme.medium,
      ),
      decoration: InputDecoration(
        hintText: context.tr('simplified_mode.skip_other_hint'),
        filled: true,
        fillColor: SimplifiedColors.surface,
        contentPadding: const EdgeInsets.all(18),
        border: border,
        enabledBorder: border,
      ),
    ),
    const SizedBox(height: 12),
    SimplifiedDarkChoice(
      label: context.tr('simplified_mode.skip_save'),
      onTap: onSave,
    ),
  ];
}

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
