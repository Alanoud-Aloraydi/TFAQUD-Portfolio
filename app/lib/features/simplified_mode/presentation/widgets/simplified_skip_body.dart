import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The question and the answers of «ليش ما أخذتها؟». Three reasons the
/// patient would give in their own words, and «سبب ثاني» for the rest:
/// the reason is never required, so no answer blocks the record.
class SimplifiedSkipBody extends StatelessWidget {
  const SimplifiedSkipBody({
    super.key,
    required this.saving,
    required this.onReason,
  });

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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
      child: Column(
        children: <Widget>[
          Text(
            context.tr('simplified_mode.skip_question'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(28, color: SimplifiedStyle.surface),
          ),
          const SizedBox(height: 28),
          for (final (String key, DoseSkipReason? reason) in _reasons) ...[
            SimplifiedButton(
              label: context.tr(key),
              tone: SimplifiedButtonTone.secondary,
              onPressed: saving ? null : () => onReason(reason),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
