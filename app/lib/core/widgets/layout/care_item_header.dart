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
  });

  final String time;
  final Widget leading;
  final Widget body;
  final Widget status;
  final VoidCallback? onTap;

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
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
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
                  status,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
