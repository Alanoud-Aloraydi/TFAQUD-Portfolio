import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/account/presentation/widgets/sent_request_line.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Where the request stands, as a line of the sheet: accepted or pending.
class SentRequestStatusLine extends StatelessWidget {
  const SentRequestStatusLine({super.key, required this.accepted});

  final bool accepted;

  @override
  Widget build(BuildContext context) {
    return SentRequestLine(
      label: context.tr('circles.request_status'),
      child: StatusBadge(
        icon: accepted ? ActionIcons.check : ScheduleIcons.clock,
        text: context.tr(
          accepted
              ? 'account.status_accepted'
              : 'circles.request_status_pending',
        ),
        tone: accepted ? StatusTone.success : StatusTone.attention,
      ),
    );
  }
}
