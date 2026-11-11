import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:flutter/material.dart';

/// The top line of a [PlanItemCard]: the kind visual, the title and
/// subtitle, then the pencil and the status at the end.
class PlanItemHeader extends StatelessWidget {
  const PlanItemHeader({
    super.key,
    required this.leading,
    required this.title,
    required this.status,
    this.subtitle,
    this.edit,
  });

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget status;
  final Widget? edit;

  @override
  Widget build(BuildContext context) {
    final bool stacked =
        MediaQuery.textScalerOf(context).scale(1) >
        AppItemCard.stackedTextScale;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppItemCard.touch),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: AppItemCard.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                title,
                ?subtitle,
                // At large text the status drops under the title instead of
                // squeezing it.
                if (stacked) status,
              ],
            ),
          ),
          ?edit,
          if (!stacked) status,
        ],
      ),
    );
  }
}
