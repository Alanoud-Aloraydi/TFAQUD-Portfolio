import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:app/core/widgets/layout/plan_item_details.dart';
import 'package:app/core/widgets/layout/plan_item_frame.dart';
import 'package:app/core/widgets/layout/plan_item_header.dart';
import 'package:flutter/material.dart';

/// The card of one plan in «الخطة» (a medicine, a measurement, an
/// appointment), built the same for each: [leading], [title], [subtitle],
/// the pencil ([edit]) and [status] on top; [body] boxes under them; and a
/// last line that opens [details], which slide down from it.
class PlanItemCard extends StatefulWidget {
  const PlanItemCard({
    super.key,
    required this.leading,
    required this.title,
    required this.status,
    required this.detailsLabel,
    this.subtitle,
    this.edit,
    this.banner,
    this.body = const <Widget>[],
    this.details = const <Widget>[],
    this.start,
  });

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget status;

  /// The pencil; null when the plan cannot be edited.
  final Widget? edit;

  /// A picture above the header, such as the medicine's photo.
  final Widget? banner;
  final List<Widget> body;

  /// What opens: «تفاصيل الدواء». The whole line is hidden when [details]
  /// is empty.
  final String detailsLabel;
  final List<Widget> details;

  /// The line's start side: «بدأ في 7 نوفمبر 2026».
  final String? start;

  @override
  State<PlanItemCard> createState() => _PlanItemCardState();
}

class _PlanItemCardState extends State<PlanItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return PlanItemFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ?widget.banner,
          PlanItemHeader(
            leading: widget.leading,
            title: widget.title,
            subtitle: widget.subtitle,
            edit: widget.edit,
            status: widget.status,
          ),
          for (final Widget part in widget.body) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            part,
          ],
          if (widget.details.isNotEmpty)
            PlanDetailsToggle(
              start: widget.start,
              label: widget.detailsLabel,
              expanded: _expanded,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
          // The details slide down from the line that opens them.
          if (widget.details.isNotEmpty)
            PlanItemDetails(open: _expanded, details: widget.details),
        ],
      ),
    );
  }
}
