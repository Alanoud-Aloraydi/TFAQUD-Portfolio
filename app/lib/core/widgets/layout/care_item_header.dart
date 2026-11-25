import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/care_item_line.dart';
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
    this.spokenLabel,
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
  final String? spokenLabel;

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
      builder: (BuildContext context, BoxConstraints box) => CareItemLine(
        time: time,
        leading: leading,
        text: text,
        status: status,
        stacked: stacked,
        statusMaxWidth: box.maxWidth * _statusShare,
        onTap: onTap,
        spokenLabel: spokenLabel,
      ),
    );
  }
}
