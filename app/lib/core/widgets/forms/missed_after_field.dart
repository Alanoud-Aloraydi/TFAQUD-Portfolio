import 'dart:async';

import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/minutes_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The minutes after which a dose or reading counts as missed, chosen on
/// the ruler of «ذكّرني لاحقًا» between [PlanLimits.minMissedAfterMinutes]
/// and [PlanLimits.maxMissedAfterMinutes]: the row says it («ساعة»,
/// «45 دقيقة») and opens the ruler. The same row serves every kind of
/// plan. [focusNode] lets a form bring the row into view; [showError] says
/// the range while nothing valid is chosen.
class MissedAfterField extends StatelessWidget {
  const MissedAfterField({
    super.key,
    required this.label,
    required this.minutes,
    required this.onChanged,
    this.focusNode,
    this.showError = false,
  });

  final String label;
  final int? minutes;
  final ValueChanged<int?> onChanged;
  final FocusNode? focusNode;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final int? value = minutes;
    final bool valid = PlanLimits.isValidMissedAfter(value);
    return InsetRow(
      label: label,
      value: valid ? durationWords(context, value!) : null,
      showChevron: true,
      focusNode: focusNode,
      errorText: showError && !valid
          ? context.tr(
              'plan_limits.missed_after_range',
              args: <String>[
                '${PlanLimits.minMissedAfterMinutes}',
                '${PlanLimits.maxMissedAfterMinutes}',
              ],
            )
          : null,
      onTap: () => unawaited(_pick(context)),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final int? chosen = await showMinutesSheet(
      context,
      title: label,
      minutes: minutes ?? PlanLimits.defaultMissedAfterMinutes,
      min: PlanLimits.minMissedAfterMinutes,
      max: PlanLimits.maxMissedAfterMinutes,
      headline: (int minutes) => afterDuration(context, minutes),
      subline: (_) => context.tr('plan_limits.missed_after_note'),
    );
    if (chosen != null) onChanged(chosen);
  }
}
