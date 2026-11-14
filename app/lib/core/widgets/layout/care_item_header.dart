import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The top line of a [CareItemRow]: time, kind icon, the text column and the
/// status. The whole line is one tap target and one screen-reader item.
class CareItemHeader extends StatelessWidget {
  const CareItemHeader({
    super.key,
    required this.time,
    required this.leading,
    required this.body,
    required this.status,
    this.onTap,
    this.spoken,
  });

  final String time;
  final Widget leading;
  final Widget body;
  final Widget status;
  final VoidCallback? onTap;

  /// What a screen reader says for the whole line. Merged alone, the line
  /// is read in the order it is laid out, which starts with the time: on a
  /// day of four doses every row then opens with a number. Given here, the
  /// line names the thing first.
  final String? spoken;

  /// The most of the line the status takes beside the text.
  static const double _statusShare = 0.4;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final bool stacked = scaler.scale(1) > AppItemCard.stackedTextScale;
    final Widget text = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          body,
          if (stacked) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            status,
          ],
        ],
      ),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) =>
          _line(context, text, scaler, stacked, box.maxWidth),
    );
  }

  Widget _line(
    BuildContext context,
    Widget text,
    TextScaler scaler,
    bool stacked,
    double width,
  ) {
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: spoken,
        excludeSemantics: spoken != null,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppItemCard.touch),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: scaler.scale(AppItemCard.timeColumn),
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
                    constraints: BoxConstraints(maxWidth: width * _statusShare),
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
