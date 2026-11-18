import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «بانتظار ردّك» on an invitation or a request nobody answered yet.
class NeedsReplyPill extends StatelessWidget {
  const NeedsReplyPill({super.key});

  @override
  Widget build(BuildContext context) => StatusBadge(
    icon: ScheduleIcons.clock,
    text: context.tr('circles.needs_reply_pill'),
    tone: StatusTone.attention,
  );
}
