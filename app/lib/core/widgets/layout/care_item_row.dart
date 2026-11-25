import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
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
    this.spokenLabel,
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

  /// What a screen reader says for the header line ([CareItemHeader]).
  final String? spokenLabel;

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
            spokenLabel: spokenLabel,
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
