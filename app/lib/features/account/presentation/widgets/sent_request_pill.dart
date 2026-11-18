import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Where a sent request stands, short enough for its row: accepted or
/// still pending.
class SentRequestPill extends StatelessWidget {
  const SentRequestPill({super.key, required this.accepted});

  final bool accepted;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      icon: accepted ? ActionIcons.check : ScheduleIcons.clock,
      text: context.tr(
        accepted
            ? 'account.status_accepted_short'
            : 'circles.request_status_pending',
      ),
      background: AppSemanticColors.background,
      foreground: accepted
          ? AppSemanticColors.statusSuccess
          : context.tokens.textSecondary,
    );
  }
}
