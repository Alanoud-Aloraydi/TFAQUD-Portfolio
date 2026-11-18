import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dark_choice.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// «ليش ما أخذتها؟» over the medicine's name, then three reasons in the
/// patient's own words and «سبب ثاني» for the rest: the reason is never
/// required, so no answer blocks the record.
class SimplifiedSkipBody extends StatelessWidget {
  const SimplifiedSkipBody({
    super.key,
    required this.name,
    required this.saving,
    required this.onReason,
  });

  /// The medicine that was not taken.
  final String name;
  final bool saving;
  final void Function(DoseSkipReason? reason) onReason;

  static const List<(String, DoseSkipReason?)> _reasons =
      <(String, DoseSkipReason?)>[
        ('simplified_mode.skip_forgotten', DoseSkipReason.forgotten),
        ('simplified_mode.skip_unavailable', DoseSkipReason.unavailable),
        ('simplified_mode.skip_side_effects', DoseSkipReason.sideEffects),
        ('simplified_mode.skip_other', null),
      ];

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      // The question and what it is about read as one sentence.
      MergeSemantics(
        child: Column(
          children: <Widget>[
            Text(
              context.tr('simplified_mode.skip_question'),
              textAlign: TextAlign.center,
              style: SimplifiedStyle.head(
                SimplifiedStyle.display,
                color: SimplifiedColors.surface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              style: SimplifiedStyle.text(
                SimplifiedStyle.title,
                color: SimplifiedColors.onDarkMuted,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      for (final (String key, DoseSkipReason? reason) in _reasons)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SimplifiedDarkChoice(
            label: context.tr(key),
            onTap: saving ? null : () => onReason(reason),
          ),
        ),
    ],
  );
}
