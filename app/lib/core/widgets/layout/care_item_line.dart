import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:flutter/material.dart';

/// The laid-out line of a [CareItemHeader]: the time column, the kind icon,
/// the [text] and, beside it when the text is not stacked, the [status].
/// One tap target and one screen-reader item.
class CareItemLine extends StatelessWidget {
  const CareItemLine({
    super.key,
    required this.time,
    required this.leading,
    required this.text,
    required this.status,
    required this.stacked,
    required this.statusMaxWidth,
    this.onTap,
    this.spokenLabel,
  });

  final String time;
  final Widget leading;

  /// The text column, already expanded to fill the line.
  final Widget text;
  final Widget status;

  /// True when the status sits under the text instead of beside it.
  final bool stacked;
  final double statusMaxWidth;
  final VoidCallback? onTap;
  final String? spokenLabel;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: spoken(spokenLabel),
        excludeSemantics: spokenLabel != null,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppItemCard.touch),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: MediaQuery.textScalerOf(context)
                      .scale(AppItemCard.timeColumn),
                  child: Text(
                    time,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: AppItemCard.gap),
                leading,
                const SizedBox(width: AppItemCard.gap),
                text,
                if (!stacked) ...<Widget>[
                  const SizedBox(width: AppItemCard.gap),
                  // A long badge wraps inside its share of the line rather
                  // than squeezing the name into a column of letters.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: statusMaxWidth),
                    child: status,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
