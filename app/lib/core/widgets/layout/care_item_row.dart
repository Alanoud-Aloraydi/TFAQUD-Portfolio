import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/care_item_header.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:flutter/material.dart';

/// One piece of care in «اليوم» (a dose, a measurement, an appointment),
/// laid out the same for each: the time, the kind icon, the title with a
/// subtitle and more lines, the status, and the actions under them. The
/// tone, shell and spacing come from [TodayRowCard] and [AppItemCard].
class CareItemRow extends StatelessWidget {
  const CareItemRow({
    super.key,
    required this.time,
    required this.leading,
    required this.title,
    required this.status,
    this.subtitle,
    this.details = const <Widget>[],
    this.actions,
    this.tone = TodayRowTone.normal,
    this.onTap,
  });

  final String time;
  final Widget leading;
  final String title;
  final String? subtitle;

  /// Extra lines under the subtitle (value, who recorded it, skip reason).
  final List<Widget> details;
  final Widget status;

  /// Buttons under the header, kept out of its tap target.
  final Widget? actions;
  final TodayRowTone tone;

  /// Opens the item; null leaves the row plain.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? subtitle = this.subtitle;
    return TodayRowCard(
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CareItemHeader(
            time: time,
            leading: leading,
            status: status,
            onTap: onTap,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: text.titleSmall),
                if (subtitle != null) Text(subtitle, style: text.bodySmall),
                ...details,
              ],
            ),
          ),
          if (actions != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            actions!,
          ],
        ],
      ),
    );
  }
}
