import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/status/status_badge.dart';
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

/// «إلغاء الطلب», full width, in the error red.
class SentRequestCancelButton extends StatelessWidget {
  const SentRequestCancelButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        // Cancelling a request cannot be undone: the error red.
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppSemanticColors.statusError,
          side: const BorderSide(color: AppSemanticColors.borderControlBase),
        ),
        child: Text(context.tr('circles.cancel_request')),
      ),
    );
  }
}

/// Renders the line element of sent request sheet.
class SentRequestLine extends StatelessWidget {
  const SentRequestLine({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.tokens.textSecondary),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
